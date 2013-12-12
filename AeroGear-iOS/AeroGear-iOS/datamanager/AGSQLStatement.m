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

#import "AGSQLStatement.h"
#import "FMDatabase.h"
#import "AGEncoder.h"


@implementation AGSQLStatement

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

-(NSArray *)read:(NSString*) recordId {
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

@end