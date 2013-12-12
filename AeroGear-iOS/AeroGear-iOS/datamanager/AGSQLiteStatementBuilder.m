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

#import "AGSQLiteStatementBuilder.h"

@implementation AGSQLiteStatementBuilder
NSString *_storeName = nil;
NSString *_primaryKey = nil;
id<AGEncoder> _encoder;

+ (AGSQLiteStatementBuilder *)sharedInstance {
    static AGSQLiteStatementBuilder *__sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [[self alloc] init];
    });
    
    return __sharedInstance;
}

-(id)initWithStoreName:(NSString *)storeName encoder:(id<AGEncoder>)encoder andPrimaryKeyName:(NSString *)key {
    self = [super init];
    if (self) {
        _storeName = storeName;
        _primaryKey = key;
        _encoder = encoder;
    }
    return self;
}

-(NSString *) buildSelectStatementWithPrimaryKeyValue:(NSString*)value {
    NSString *statement = nil;
    if (_primaryKey && value) {
        statement =[ NSString stringWithFormat:@"select oid, value from %@ where %@=%@", _storeName, _primaryKey, value];
    } else {
        statement = [NSString stringWithFormat:@"select oid, value from %@", _storeName];
    }
    return statement;
}

-(NSString *)buildInsertStatementWithValue:(NSDictionary *)value {
    NSString *statement = nil;
    
    if([value count] != 0 && _storeName != nil && [_storeName isKindOfClass:[NSString class]]) {
        NSEnumerator *columnNames = [value keyEnumerator];
        NSString* primaryKeyValue = nil;
        for (NSString* col in columnNames) {
            if([col isEqualToString:_primaryKey]) {
                primaryKeyValue = value[col];
            }
        }
        //NSString *serializedString = [NSString stringWithFormat:@"%@", [_encoder encode:value error:nil]];
        NSData *data = [_encoder encode:value error:nil];
        statement =[NSString stringWithFormat:@"insert into %@ values (%@,'%@')", _storeName, primaryKeyValue, data];
    }
    return statement;
}

-(NSString *)buildUpdateStatementWithValue:(NSDictionary *)value {
    NSString *statement = nil;
    
    if([value count] != 0 && _storeName != nil && [_storeName isKindOfClass:[NSString class]]) {
        NSEnumerator *columnNames = [value keyEnumerator];
        NSString* primaryKeyValue = nil;
        for (NSString* col in columnNames) {
            if([col isEqualToString:_primaryKey]) {
                primaryKeyValue = value[col];
            }
        }
        if (primaryKeyValue == nil) {
            return nil;
        }
        
        NSString *serializedString = [NSString stringWithFormat:@"%@", [_encoder encode:value error:nil]];
        
        statement = [NSString stringWithFormat:@"update %@ set value =  '%@' where id = %@", _storeName, serializedString, primaryKeyValue];
    }
    return statement;
}

-(NSString *)buildCreateStatementWithValue:(NSDictionary *)value {
    NSMutableString *statement = nil;
    
    if([value count] != 0 && _storeName != nil && [_storeName isKindOfClass:[NSString class]]) {
        statement = [NSMutableString stringWithFormat:@"create table %@ (", _storeName];
        
        NSEnumerator *columnNames = [value keyEnumerator];
        BOOL primaryKeyFound = NO;
        for (NSString* col in columnNames) {
            if([col isEqualToString:_primaryKey]) {
                [statement appendFormat:@"%@ integer primary key asc, ", col];
                primaryKeyFound = YES;
            }
        }

        if (!primaryKeyFound) {
           [statement appendFormat:@"%@ integer primary key asc, ", _primaryKey];
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
    if(_storeName != nil && [_storeName isKindOfClass:[NSString class]]) {
        statement = [NSMutableString stringWithFormat:@"drop table %@;", _storeName];
    }
    return statement;
}

-(NSString *) buildDeleteStatementForId:(id)record {
    NSMutableString *statement = nil;
    
    if(record != nil && _storeName != nil && [_storeName isKindOfClass:[NSString class]]) {
        statement = [NSMutableString stringWithFormat:@"delete from %@ where %@ = \"%@\"", _storeName, _primaryKey, record];
    }
    return statement;
}

@end
