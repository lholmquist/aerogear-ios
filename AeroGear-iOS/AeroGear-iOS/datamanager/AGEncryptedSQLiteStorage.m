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

#import "AGEncryptedSQLiteStorage.h"
#import "AGSQLStatement.h"

@implementation AGEncryptedSQLiteStorage

// ==============================================
// ======== 'factory' and 'init' section ========
// ==============================================

+(id) storeWithConfig:(id<AGStoreConfig>) storeConfig {
    return [[self alloc] initWithConfig:storeConfig];
}

-(id) initWithConfig:(id<AGStoreConfig>) storeConfig {
    self = [super init];
    if (self) {
        _type = @"ENCRYPTED_SQLITE";

        AGStoreConfiguration* config = (AGStoreConfiguration*) storeConfig;
        _recordId = config.recordId;

        // extract file path
        _path = [self getFilePath];
        _databaseName = config.name;

        // if file exists open DB, if file not exist create an empty one
        _database = [FMDatabase databaseWithPath:[NSString stringWithFormat:@"%@.sqlite3", [_path stringByAppendingPathComponent:_databaseName]]];
        NSLog(@"Database in %@",[_path stringByAppendingPathComponent:_databaseName]);

        _encoder = [[AGEncryptedPListEncoder alloc] initWithEncryptionService:storeConfig.encryptionService];

        _statementBuilder = [[AGSQLiteStatementBuilder alloc] initWithStoreName:_databaseName encoder:_encoder andPrimaryKeyName:_recordId];


    }

    return self;
}

// =====================================================
// ======== public API (AGStore)                ========
// =====================================================

-(NSArray*) readAll {
    AGSQLStatement * command = [[AGSQLStatement alloc] initWithDatabase:_database name:_databaseName recordId:_recordId encoder:_encoder];
    return [command read:nil];
}

-(id) read:(id)recordId {
    AGSQLStatement * command = [[AGSQLStatement alloc] initWithDatabase:_database name:_databaseName recordId:_recordId encoder:_encoder];
    NSArray* results = [command read:recordId];
    if ([results count] == 0) {
        return nil;
    } else {
        return results;
    }
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
            
            statusCode = [self createTableWith: data[0] error:error];

            for (id record in data) {
                statusCode = [self saveOne:record error:error];
            }
            
        } else if([data isKindOfClass:[NSDictionary class]]) {
            // single obj:
            statusCode = [self createTableWith: data error:error];
            if (statusCode) {
                statusCode = [self saveOne:data error:error];
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
-(BOOL) saveOne:(NSDictionary*)value error:(NSError**)error {
    BOOL statusCode = YES;
    AGSQLStatement * saveCommand = [[AGSQLStatement alloc] initWithDatabase:_database name:_databaseName recordId:_recordId encoder:_encoder];
    [saveCommand save:value];
    return statusCode;
}

// create if not exist
-(BOOL) createTableWith:(NSDictionary*)value error:(NSError**)error {
    BOOL statusCode = YES;
    NSString *createStatement = [_statementBuilder buildCreateStatementWithValue:value];
    [_database open];
    if (createStatement != nil) {
        [_database executeUpdate:createStatement];
    } else {
        statusCode = NO;
        if (error) {
            *error = [self constructError:@"save" msg:@"create table failed"];
        }
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

@end
