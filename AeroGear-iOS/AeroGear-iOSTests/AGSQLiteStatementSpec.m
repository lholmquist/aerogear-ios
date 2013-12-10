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

#import <Kiwi/Kiwi.h>
#import "AGSQLiteStatementBuilder.h"

SPEC_BEGIN(AGSQLiteStatementSpec)

describe(@"AGSQLiteStatementBuilder", ^{
    context(@"builds a create statement", ^{

        __block AGSQLiteStatementBuilder *builder = nil;
        __block NSString *createStatement = nil;
        __block NSDictionary *data = nil;
        
        beforeEach(^{
            builder = [[AGSQLiteStatementBuilder alloc] initWithStoreName:@"myTable" andPrimaryKeyName:@"id"];
            data = @{@"id" : @"1",
                     @"name" : @"David",
                     @"city" : @"New York",
                     @"salary" : @"1000"};

        });
        
        it(@"should be nil with empty data", ^{
            createStatement = [builder buildCreateStatementWithValue:nil];
            [createStatement shouldBeNil];
        });

        it(@"with string dictionary should return SQL create statement with text columns ", ^{
            createStatement = [builder buildCreateStatementWithValue:data];
            [createStatement shouldNotBeNil];
            [[createStatement should] equal:@"create table myTable (id integer primary key asc, value text);"];
        });
        
        it(@"with mixed type dictionary should return SQL create statement with 2 columns: id and value ", ^{
            data = @{@"id" : @"1",
                     @"name" : @"David",
                     @"city" : @YES,
                     @"salary" : [NSNumber numberWithInt:2100]};
            createStatement = [builder buildCreateStatementWithValue:data];
            [createStatement shouldNotBeNil];
            [[createStatement should] equal:@"create table myTable (id integer primary key asc, value text);"];
        });
    });
    
    context(@"builds a select statement", ^{
        
        __block AGSQLiteStatementBuilder *builder = nil;
        __block NSString *statement = nil;
        __block NSDictionary *data = nil;
        
        beforeEach(^{
            builder = [[AGSQLiteStatementBuilder alloc] initWithStoreName:@"myTable" andPrimaryKeyName:@"id"];
            data = @{@"id" : @"1",
                     @"name" : @"David",
                     @"city" : @"New York",
                     @"salary" : @"1000"};
            
        });
        
        it(@"with id", ^{
            statement = [builder buildSelectStatementWithPrimaryKeyValue:@"1"];
            [statement shouldNotBeNil];
            [[statement should] equal:@"select oid, value from myTable where id=1"];
        });
        
        it(@"without id", ^{
            statement = [builder buildSelectStatementWithPrimaryKeyValue:nil];
            [statement shouldNotBeNil];
            [[statement should] equal:@"select oid, value from myTable"];
        });
        
    });
    context(@"builds an insert statement", ^{

        __block AGSQLiteStatementBuilder *builder = nil;
        __block NSString *statement = nil;
        __block NSDictionary *data = nil;
        
        beforeEach(^{
            builder = [[AGSQLiteStatementBuilder alloc] initWithStoreName:@"myTable" andPrimaryKeyName:@"id"];
            data = @{@"id" : @"1",
                     @"name" : @"David",
                     @"city" : @"New York",
                     @"salary" : @"1000"};
            
        });
        
        it(@"should be nil with empty data", ^{
            statement = [builder buildInsertStatementWithValue:nil];
            [statement shouldBeNil];
        });
        
        it(@"with string dictionary should return SQL insert statement with JSON value", ^{
            statement = [builder buildInsertStatementWithValue:data];
            [statement shouldNotBeNil];

            [[statement should] equal:@"insert into myTable values (1,'<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n<dict>\n\t<key>city</key>\n\t<string>New York</string>\n\t<key>id</key>\n\t<string>1</string>\n\t<key>name</key>\n\t<string>David</string>\n\t<key>salary</key>\n\t<string>1000</string>\n</dict>\n</plist>\n')"];
        });
        
    });
    
    context(@"builds an update statement", ^{
        
        __block AGSQLiteStatementBuilder *builder = nil;
        __block NSString *statement = nil;
        __block NSDictionary *data = nil;
        
        beforeEach(^{
            builder = [[AGSQLiteStatementBuilder alloc] initWithStoreName:@"myTable" andPrimaryKeyName:@"id"];
            data = @{@"id" : @"1",
                     @"name" : @"David",
                     @"city" : @"New York",
                     @"salary" : @"1000"};
            
        });
        
        it(@"should be nil with empty data", ^{
            statement = [builder buildUpdateStatementWithValue:nil];
            [statement shouldBeNil];
        });
        
        it(@"with string dictionary should return SQL update statement with JSON value", ^{
            statement = [builder buildUpdateStatementWithValue:data];
            [statement shouldNotBeNil];
            [[statement should] equal:@"update myTable set value =  '<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n<dict>\n\t<key>city</key>\n\t<string>New York</string>\n\t<key>id</key>\n\t<string>1</string>\n\t<key>name</key>\n\t<string>David</string>\n\t<key>salary</key>\n\t<string>1000</string>\n</dict>\n</plist>\n' where id = 1"];
        });
        
    });
    
    context(@"builds an drop statement", ^{
        
        __block AGSQLiteStatementBuilder *builder = nil;
        __block NSString *statement = nil;
        
        beforeEach(^{
            builder = [[AGSQLiteStatementBuilder alloc] initWithStoreName:nil andPrimaryKeyName:nil];
        });
        
        it(@"should be nil with empty data", ^{
            statement = [builder buildDropStatement];
            [statement shouldBeNil];
        });
        
        it(@"should have valid SQL syntax", ^{
            builder = [[AGSQLiteStatementBuilder alloc] initWithStoreName:@"myTable" andPrimaryKeyName:nil];
            statement = [builder buildDropStatement];
            [statement shouldNotBeNil];
            [[statement should] equal:@"drop table myTable;"];
        });
    });
    
    
    context(@"builds an delete statement", ^{
        
        __block AGSQLiteStatementBuilder *builder = nil;
        __block NSString *statement = nil;
        
        beforeEach(^{
            builder = [[AGSQLiteStatementBuilder alloc] initWithStoreName:@"myTable" andPrimaryKeyName:@"id"];
        });
        
        it(@"should be nil with empty data", ^{
            builder = [[AGSQLiteStatementBuilder alloc] initWithStoreName:nil andPrimaryKeyName:@"id"];
            statement = [builder buildDeleteStatementForId:@"1"];
            [statement shouldBeNil];
        });
        
        it(@"should have valid SQL syntax", ^{
            statement = [builder buildDropStatement];
            [statement shouldNotBeNil];
            [[statement should] equal:@"drop table myTable;"];
        });
    });
});

SPEC_END