/*
 * JBoss, Home of Professional Open Source.
 * Copyright Red Hat, Inc., and individual contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "AGSQLiteStorage.h"
#import "AGSQLiteStatementBuilder.h"
#import "AGEncoder.h"

@implementation AGSQLiteStorage {
    NSString* _databaseName;
    NSString* _path;
    AGSQLiteStatementBuilder* _statementBuilder;
    id<AGEncoder> _encoder;
}

@synthesize type = _type;

// ==============================================
// ======== 'factory' and 'init' section ========
// ==============================================

+(id) storeWithConfig:(id<AGStoreConfig>) storeConfig {
    return [[self alloc] initWithConfig:storeConfig];
}

-(id) initWithConfig:(id<AGStoreConfig>) storeConfig {
    self = [super init];
    if (self) {
        // base inits:
        _type = @"SQLITE";
        
        AGStoreConfiguration* config = (AGStoreConfiguration*) storeConfig;
        _recordId = config.recordId;
        
        // extract file path
        _path = [self getFilePath];
        _databaseName = config.name;

        // if file exists open DB, if file not exist create an empty one
        _database = [FMDatabase databaseWithPath:[NSString stringWithFormat:@"%@.sqlite3", [_path stringByAppendingPathComponent:_databaseName]]];
        NSLog(@"Database in %@",[_path stringByAppendingPathComponent:_databaseName]);
        
        _statementBuilder = [[AGSQLiteStatementBuilder alloc] initWithStoreName:_databaseName andPrimaryKeyName:_recordId];
        
        _encoder = [[AGPListEncoder alloc] init];
    }
    
    return self;
}

-(NSError *) constructError:(NSString*) domain
                        msg:(NSString*) msg {
    
    NSError* error = [NSError errorWithDomain:[NSString stringWithFormat:@"org.aerogear.stores.%@", domain]
                                         code:0
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:msg,
                                               NSLocalizedDescriptionKey, nil]];
    
    return error;
}

// =====================================================
// ======== public API (AGStore)                ========
// =====================================================

-(NSArray*) readAll {
    NSString* query = [_statementBuilder buildSelectStatementWithPrimaryKeyValue:nil];
    NSArray* results = [self readWithQuery:query];
    NSMutableArray* deserializedResults = [[NSMutableArray alloc] init];

    for (id record in results) {
        id jsonObject = [self deserialiseValue:record];
        if (jsonObject && [jsonObject isKindOfClass:[NSDictionary class]]) {
             [deserializedResults addObject:jsonObject];
        }
    }

    return deserializedResults;
}

-(id) read:(id)recordId {
    NSString* query = [_statementBuilder buildSelectStatementWithPrimaryKeyValue:recordId];
    NSArray* results = [self readWithQuery:query];
    if ([results count] == 0) {
        return nil;
    } else {
        id jsonObject = [self deserialiseValue:results[0]];
        if (jsonObject != nil && [jsonObject isKindOfClass:[NSDictionary class]]) {
            return (NSDictionary *)jsonObject;
        }
    }
    return nil;
}


-(NSArray*) filter:(NSPredicate*)predicate {
    NSArray* results = [self readAll];
    return [results filteredArrayUsingPredicate:predicate];
}


-(BOOL) save:(id)data error:(NSError**)error {
    BOOL statusCode = YES;
    if ([_encoder isValid:data]) {
        // a 'collection' of objects:
        if ([data isKindOfClass:[NSArray class]]) {
            // fail fast if the array contains non-dictionary objects
            for (id record in data) {
                if (![record isKindOfClass:[NSDictionary class]]) {
                    if (error) {
                        *error = [self constructError:@"save" msg:@"array contains non-dictionary objects!"];
                        return NO;
                    }
                }
            }
            
            if ([data count] != 0) {
                statusCode = [self createTableWith: data[0]];
            } else {
                if (error) {
                    *error = [self constructError:@"save" msg:@"create table failed"];
                }
            }
            for (id record in data) {
                statusCode = [self saveOne:record];
                if (!statusCode && error) {
                    *error = [self constructError:@"save" msg:@"insert into table failed"];
                }
            }
            
        } else if([data isKindOfClass:[NSDictionary class]]) {
            // single obj:
            statusCode = [self createTableWith: data];
            if (statusCode) {
                statusCode = [self saveOne:data];
                if (!statusCode && error) {
                    *error = [self constructError:@"save" msg:@"insert into table failed"];
                }
            } else {
                if (error) {
                    *error = [self constructError:@"save" msg:@"create table failed"];
                }
            }
            
        } else { // not a dictionary, fail back
            if (error) {
                *error = [self constructError:@"save" msg:@"dictionary objects are supported only"];
            }
            return NO;
            
        }
    } else {
        if (error) {
            *error = [self constructError:@"save" msg:@"supported values should be either NSString, NSNumber, NSArray, NSDictionary, or NSNull"];
        }
        return NO;
    }
    
    return statusCode;
}

// private save for one item:
-(BOOL) saveOne:(NSDictionary*)value {
    BOOL statusCode = YES;
    NSString *insertStatement = nil;
    insertStatement = [_statementBuilder buildInsertStatementWithValue:value];
    [_database open];
    statusCode = [_database executeUpdate:insertStatement];
    if (!statusCode) { //insert fails => update
        NSString* updateStatement = [_statementBuilder buildUpdateStatementWithValue:value];
        statusCode = [_database executeUpdate:updateStatement];
    } else { // for insert update id
        int lastId = [_database lastInsertRowId];
        [value setValue:[NSString stringWithFormat:@"%d", lastId] forKey:_recordId];
    }
    [_database close];
    return statusCode;
}

// create if not exist
-(BOOL) createTableWith:(NSDictionary*)value {
    BOOL statusCode = YES;
    NSString *createStatement = [_statementBuilder buildCreateStatementWithValue:value];
    [_database open];
    if (createStatement != nil) {
        [_database executeUpdate:createStatement];
    } else {
        statusCode = NO;
    }
    [_database close];
    return statusCode;
}


-(BOOL) reset:(NSError**)error {
    BOOL statusCode = YES;
    NSString *dropStatement = [_statementBuilder buildDropStatement];
    [_database open];
    if (dropStatement != nil) {
         [_database executeUpdate:dropStatement];
    } else {
        statusCode = NO;
        if (!statusCode && error) {
            *error = [self constructError:@"reset" msg:@"drop table failed"];
        }
    }
    [_database close];
    return statusCode;
}

-(BOOL) isEmpty {
    NSArray *all = [self readAll];
    if ([all count] == 0) {
        return YES;
    }
    return NO;
}

-(BOOL) remove:(id)record error:(NSError**)error {
    BOOL statusCode = YES;
    NSString *idString = nil;
    BOOL isNull = [record isKindOfClass:[NSNull class]];
    if (!isNull && record != nil && record[_recordId] != nil) {
        idString = record[_recordId];
        NSString *deleteStatement = [_statementBuilder buildDeleteStatementForId:idString];
        [_database open];
        if (deleteStatement != nil) {
            [_database executeUpdate:deleteStatement];
        } else {
            statusCode = NO;
            if (!statusCode && error) {
                *error = [self constructError:@"remove" msg:@"drop table failed"];
            }
        }
        [_database close];
    } else {
        statusCode = NO;
        if (!statusCode && error) {
            *error = [self constructError:@"remove" msg:@"remove a nil id not possible"];
        }
    }
    
    return statusCode;
}


// =====================================================
// =========== private utility methods  ================
// =====================================================
-(NSString*) getFilePath {
    // calculate path
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    
    // create the Documents directory if it doesn't exist
    BOOL isDir;
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentsDirectory isDirectory:&isDir]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory
                                  withIntermediateDirectories:YES attributes:nil error:&error];
    }
    return documentsDirectory;
    
}

-(NSArray*) readWithQuery:(NSString*) query {
    [_database open];
    
    NSMutableArray *results = [NSMutableArray array];
    FMResultSet *myResults = [_database executeQuery:query];
    while ([myResults next]) {
        [results addObject:[myResults resultDictionary]];
    }
    
    [_database close];
    return results;
}

-(id) deserialiseValue:(id) record {
    NSString* jsonString = record[@"value"];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    return [_encoder decode:jsonData error:nil];
}

@end
