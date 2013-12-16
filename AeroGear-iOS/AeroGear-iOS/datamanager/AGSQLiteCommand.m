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

#import "AGSQLiteCommand.h"
#import "FMDatabase.h"
#import "AGEncoder.h"


@implementation AGSQLiteCommand

- (id)initWithDatabase:(FMDatabase *)database name:(NSString*)name recordId:(NSString*)recordId encoder:(id<AGEncoder>) encoder{
    if(self = [super init]) {
        _database = database;
        _tableName = name;
        _recordId = recordId;
        _encoder = encoder;
    }
    return self;
}

- (BOOL)save:(NSMutableDictionary *)value {
    assert(value!=nil);
    BOOL returnStatus = YES;

    if(value[_recordId] == nil || [[self read:value[_recordId]] count] == 0) {
        [_database open];
        NSData* data = [_encoder encode:value error:nil];
        returnStatus = [_database executeUpdate:@"insert into Users (oid, value) values (?, ?);", value[_recordId],data];
        int lastId = [_database lastInsertRowId];
        [value setValue:[NSString stringWithFormat:@"%d", lastId] forKey:_recordId];
        [_database close];
    } else {
        [_database open];
        NSData* data = [_encoder encode:value error:nil];
        NSMutableString* builderString = [[NSMutableString alloc] init];
        [builderString appendString:@"update "];
        [builderString appendString:_tableName];
        [builderString appendString:@" set value = ? where id = ?"];
        returnStatus = [_database executeUpdate:builderString, value[_recordId], data];
        [_database close];
     }

    return returnStatus;
}

-(id)read:(NSString*) recordId {
    [_database open];
    FMResultSet *dbResults;
    id result;
    if(recordId == nil) {
        dbResults = [_database executeQuery:[NSString stringWithFormat:@"select oid, value from %@", _tableName]];
        NSMutableArray *results = [NSMutableArray array];
        while([dbResults next]) {
            NSData* readData = [dbResults dataForColumn:@"value"];
            NSMutableDictionary* val = [[_encoder decode:readData error:nil] mutableCopy];
            if (val) {
                val[_recordId] = [dbResults stringForColumnIndex:0];
            }
            [results addObject:val];
        }
        result = results ;
    } else {
        dbResults = [_database executeQuery:[NSString stringWithFormat:@"select oid, value from %@ where oid = %@", _tableName, recordId]];
        NSMutableDictionary* val;
        if([dbResults next]) {
            NSData* readData = [dbResults dataForColumn:@"value"];
            val = [[_encoder decode:readData error:nil] mutableCopy];
            if (val) {
                val[_recordId] = [dbResults stringForColumnIndex:0];
            }
        }
        result = val;
    }
    [_database close];
    return result;
}

-(BOOL) createTableWith:(NSDictionary*)value error:(NSError**)error {
    BOOL statusCode = YES;
    NSString *createStatement = [self buildCreateStatementWithValue:value];
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
    NSString *dropStatement = [self buildDropStatement];
    [_database open];
    if (dropStatement != nil) {
        [_database executeUpdate:dropStatement];
    } else {
        statusCode = NO;
        if (error) {
            *error = [self constructError:@"reset" msg:@"drop table failed"];
        }
    }
    [_database close];
    return statusCode;
}

-(BOOL) remove:(id)record error:(NSError**)error {
    BOOL statusCode = YES;
    NSString *idString = nil;
    BOOL isNull = [record isKindOfClass:[NSNull class]];
    if (!isNull && record != nil && record[_recordId] != nil) {
        idString = record[_recordId];
        NSString *deleteStatement = [self buildDeleteStatementForId:idString];
        [_database open];
        if (deleteStatement != nil) {
            [_database executeUpdate:deleteStatement];
        } else {
            statusCode = NO;
            if (error) {
                *error = [self constructError:@"remove" msg:@"drop table failed"];
            }
        }
        [_database close];
    } else {
        statusCode = NO;
        if (error) {
            *error = [self constructError:@"remove" msg:@"remove a nil id not possible"];
        }
    }

    return statusCode;
}

// =====================================================
// ======== private methods                     ========
// =====================================================
-(NSString *) buildDeleteStatementForId:(id)record {
    NSMutableString *statement = nil;

    if(record != nil && _tableName != nil && [_tableName isKindOfClass:[NSString class]]) {
        statement = [NSMutableString stringWithFormat:@"delete from %@ where %@ = \"%@\"", _tableName, _recordId, record];
    }
    return statement;
}

-(NSString *)buildCreateStatementWithValue:(NSDictionary *)value {
    NSMutableString *statement = nil;

    if([value count] != 0 && _tableName != nil && [_tableName isKindOfClass:[NSString class]]) {
        statement = [NSMutableString stringWithFormat:@"create table %@ (", _tableName];

        NSEnumerator *columnNames = [value keyEnumerator];
        BOOL primaryKeyFound = NO;
        for (NSString* col in columnNames) {
            if([col isEqualToString:_recordId]) {
                [statement appendFormat:@"%@ integer primary key asc, ", col];
                primaryKeyFound = YES;
            }
        }

        if (!primaryKeyFound) {
            [statement appendFormat:@"%@ integer primary key asc, ", _recordId];
        }
        NSString* type = @"text, ";
        if ([_encoder isKindOfClass:[AGEncryptedPListEncoder class]]) {
            type = @"blob, ";
        }
        [statement appendFormat:@"value "];
        [statement appendFormat:type];
        [statement deleteCharactersInRange:NSMakeRange([statement length]- 2, 2)];
        [statement appendFormat:@");"];
    }
    return statement;
}

-(NSString *) buildDropStatement {
    NSMutableString *statement = nil;
    if(_tableName != nil && [_tableName isKindOfClass:[NSString class]]) {
        statement = [NSMutableString stringWithFormat:@"drop table %@;", _tableName];
    }
    return statement;
}

-(NSError *) constructError:(NSString*) domain
                        msg:(NSString*) msg {

    NSError* error = [NSError errorWithDomain:[NSString stringWithFormat:@"org.aerogear.stores.%@", domain]
                                         code:0
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:msg,
                                                                                         NSLocalizedDescriptionKey, nil]];

    return error;
}

@end