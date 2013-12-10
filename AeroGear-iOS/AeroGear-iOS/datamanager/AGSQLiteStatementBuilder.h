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

#import <Foundation/Foundation.h>
#import "AGEncoder.h"

@interface AGSQLiteStatementBuilder : NSObject

-(id)initWithStoreName:(NSString *)storeName encoder:(id<AGEncoder>)encoder andPrimaryKeyName:(NSString *)key;
-(NSString *) buildSelectStatementWithPrimaryKeyValue:(NSString*)value;
-(NSString *) buildInsertStatementWithValue:(NSDictionary *)value;
-(NSString *) buildUpdateStatementWithValue:(NSDictionary *)value;
-(NSString *) buildCreateStatementWithValue:(NSDictionary *)value;
-(NSString *) buildDropStatement;
-(NSString *) buildDeleteStatementForId:(id)record;
@end
