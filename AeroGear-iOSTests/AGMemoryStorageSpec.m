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
#import "AGMemoryStorage.h"

SPEC_BEGIN(AGMemoryStorageSpec)

describe(@"AGMemoryStorage", ^{
    context(@"when newly created", ^{
        
        // An 'in memory' storage object:
        __block AGMemoryStorage* memStore = nil;

        beforeEach(^{
            AGStoreConfiguration* config = [[AGStoreConfiguration alloc] init];
            [config setRecordId:@"id"];
            
            memStore = [AGMemoryStorage storeWithConfig:config];
        });


        it(@"should not be nil", ^{
            [memStore shouldNotBeNil];
        });
        
        it(@"should save a single object ", ^{
            NSMutableDictionary* user1 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"Matthias",@"name",@"0",@"id", nil];
            
            BOOL success = [memStore save:user1 error:nil];
            [[theValue(success) should] equal:theValue(YES)];
            
        });

        it(@"should save a single object with no id set", ^{
            NSMutableDictionary* user = [NSMutableDictionary
                                         dictionaryWithObjectsAndKeys:@"Matthias",@"name", nil];

            BOOL success = [memStore save:user error:nil];
            [[theValue(success) should] equal:theValue(YES)];

            [[user valueForKey:@"id"] shouldNotBeNil];

        });

        it(@"should save a single object with no id set and custom id configured", ^{
            NSMutableDictionary* user = [NSMutableDictionary
                    dictionaryWithObjectsAndKeys:@"Robert",@"name", nil];

            AGStoreConfiguration* config = [[AGStoreConfiguration alloc] init];
            // apply a custom ID config...
            [config setRecordId:@"myId"];
            // re init the store:
            memStore = [AGMemoryStorage storeWithConfig:config];

            BOOL success = [memStore save:user error:nil];
            [[theValue(success) should] equal:theValue(YES)];

            // save should have set custom ID
            [[user valueForKey:@"myId"] shouldNotBeNil];

        });

        it(@"should read an object _after_ storing it", ^{
            NSMutableDictionary* user = [NSMutableDictionary
                                         dictionaryWithObjectsAndKeys:@"Matthias",@"name",@"0",@"id", nil];

            // store it
            BOOL success = [memStore save:user error:nil];
            [[theValue(success) should] equal:theValue(YES)];

            // read it
            NSMutableDictionary* object = [memStore read:@"0"];
            [[object[@"name"] should] equal:@"Matthias"];
        });

        it(@"should read an object _after_ storing it (using readAll)", ^{
            NSMutableDictionary* user1 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"Matthias",@"name",@"0815",@"id", nil];
            
            BOOL success = [memStore save:user1 error:nil];
            [[theValue(success) should] equal:theValue(YES)];

            // read it
            NSArray* objects = [memStore readAll];
            
            [[objects should] haveCountOf:1];
            [[objects should] containObjects:user1, nil];
            
            [[objects[(NSUInteger)0][@"name"] should] equal:@"Matthias"];
            [[objects[(NSUInteger)0][@"id"] should] equal:@"0815"];
        });
        
        it(@"should read nothing out of an empty store", ^{
            // read it
            NSArray* objects = [memStore readAll];
            
            [[objects should] beEmpty];
        });
        
        it(@"should read nothing out of an empty store", ^{
            // read it, should be empty
            [[theValue([memStore isEmpty]) should] equal:theValue(YES)];
            
        });
        
        it(@"should read not object out of an empty store", ^{
            NSMutableDictionary *object = [memStore read:@"someId"];
            
            [object shouldBeNil];
        });
        
        it(@"should read and save multiple objects", ^{
            NSMutableDictionary* user1 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"Matthias",@"name",@"123",@"id", nil];
            NSMutableDictionary* user2 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"abstractj",@"name",@"456",@"id", nil];
            NSMutableDictionary* user3 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"qmx",@"name",@"5",@"id", nil];
            
            NSArray* users = @[user1, user2, user3];
            
            // store it
            BOOL success = [memStore save:users error:nil];
            [[theValue(success) should] equal:theValue(YES)];
            
            // read it
            NSArray* objects = [memStore readAll];

            [[objects should] haveCountOf:(NSUInteger)3];
            [[objects should] containObjects:user1, nil];
            [[objects should] containObjects:user2, nil];
            [[objects should] containObjects:user3, nil];
        });

        it(@"should not be empty after storing objects", ^{
            NSMutableDictionary* user1 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"Matthias",@"name",@"123",@"id", nil];
            NSMutableDictionary* user2 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"abstractj",@"name",@"456",@"id", nil];
            NSMutableDictionary* user3 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"qmx",@"name",@"5",@"id", nil];
            
            NSArray* users = @[user1, user2, user3];
            
            // store it
            [memStore save:users error:nil];
           
            // check if empty:
            [[theValue([memStore isEmpty]) should] equal:theValue(NO)];
        });

        it(@"should read nothing after reset", ^{
            NSMutableDictionary* user1 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"Matthias",@"name",@"123",@"id", nil];
            NSMutableDictionary* user2 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"abstractj",@"name",@"456",@"id", nil];
            NSMutableDictionary* user3 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"qmx",@"name",@"5",@"id", nil];
            
            NSArray* users = @[user1, user2, user3];

            NSArray* objects;
            BOOL success;
            
            // store it
            success = [memStore save:users error:nil];
            [[theValue(success) should] equal:theValue(YES)];
            
            // read it
            objects = [memStore readAll];
            [[objects should] haveCountOf:(NSUInteger)3];
            [[objects should] containObjects:user1, nil];
            [[objects should] containObjects:user2, nil];
            [[objects should] containObjects:user3, nil];

            
            success = [memStore reset:nil];
            [[theValue(success) should] equal:theValue(YES)];
            
            // read from the empty store...
            objects = [memStore readAll];
            
            [[objects should] haveCountOf:(NSUInteger)0];
        });
        
        it(@"should be able to do bunch of read, save, reset operations", ^{
            NSMutableDictionary* user1 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"Matthias",@"name",@"123",@"id", nil];
            NSMutableDictionary* user2 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"abstractj",@"name",@"456",@"id", nil];
            NSMutableDictionary* user3 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"qmx",@"name",@"5",@"id", nil];
            
            NSArray* users = @[user1, user2, user3];
            
            NSArray* objects;

            BOOL success;
            
            // store it
            success = [memStore save:users error:nil];
            [[theValue(success) should] equal:theValue(YES)];
            
            // read it
            objects = [memStore readAll];
            [[objects should] haveCountOf:(NSUInteger)3];
            [[objects should] containObjects:user1, nil];
            [[objects should] containObjects:user2, nil];
            [[objects should] containObjects:user3, nil];
        
            success = [memStore reset:nil];
            
            // read from the empty store...
            objects = [memStore readAll];
            [[objects should] haveCountOf:(NSUInteger)0];

            // store it again...
            success = [memStore save:users error:nil];
            [[theValue(success) should] equal:theValue(YES)];
            
            // read it again ...
            objects = [memStore readAll];
            [[objects should] haveCountOf:(NSUInteger)3];
            [[objects should] containObjects:user1, nil];
            [[objects should] containObjects:user2, nil];
            [[objects should] containObjects:user3, nil];
        });
        
        it(@"should not be able to save a non-dictionary object", ^{
            // an arbitary object instead of an nsdictionary
            NSSet *user1 = [NSSet setWithObjects:@"Matthias",@"name",@"1",@"id", nil];
            NSError *error;
            
            BOOL success = [memStore save:user1 error:&error];
            
            [[theValue(success) should] equal:theValue(NO)];
            [[error.localizedDescription should] equal:@"dictionary objects are supported only"];
        });
        
        it(@"should not be able to save a non-dictionary object contained inside an NSArray", ^{
            // an arbitary object instead of an nsdictionary
            NSSet *user1 = [NSSet setWithObjects:@"Matthias",@"name",@"1",@"id", nil];
            
            // wrap it inside an array
            NSMutableArray *arr = [NSMutableArray arrayWithObjects:user1, nil];
            NSError *error;
            
            BOOL success = [memStore save:arr error:&error];
            
            [[theValue(success) should] equal:theValue(NO)];
            [[error.localizedDescription should] equal:@"array contains non-dictionary objects!"];
        });
        
        it(@"should not read a remove object", ^{
            NSMutableDictionary* user1 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"Matthias",@"name",@"0",@"id", nil];
            
            BOOL success;
            
            success = [memStore save:user1 error:nil];
            [[theValue(success) should] equal:theValue(YES)];

            // read it
            NSMutableDictionary *object = [memStore read:@"0"];
            [[object[@"name"] should] equal:@"Matthias"];

            // remove the above user:
            success = [memStore remove:user1 error:nil];
            [[theValue(success) should] equal:theValue(YES)];
            
            // read from the empty store...
            NSArray* objects = [memStore readAll];
            [[objects should] haveCountOf:(NSUInteger)0];
        });
        
        it(@"should not remove non-existing object", ^{
            NSMutableDictionary* user1 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"Matthias",@"name",@"0",@"id", nil];
            
            BOOL success;
            
            success = [memStore save:user1 error:nil];
            [[theValue(success) should] equal:theValue(YES)];

            // read it
            NSMutableDictionary *object = [memStore read:@"0"];
            [[object[@"name"] should] equal:@"Matthias"];

            NSMutableDictionary* user2 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"Matthias",@"name",@"1",@"id", nil];

            // remove the user with the id '1' (not existing):
            success = [memStore remove:user2 error:nil];
            [[theValue(success) should] equal:theValue(NO)];

            // should contain the first object
            NSArray* objects = [memStore readAll];
            
            [[objects should] haveCountOf:1];
        });
        
        it(@"should not be able to remove a nil object", ^{
            NSError *error;
            BOOL success;
            
            success = [memStore remove:nil error:&error];
            
            [[theValue(success) should] equal:theValue(NO)];
            [[error.localizedDescription should] equal:@"object was nil"];
            
            
            success = [memStore remove:[NSNull null] error:&error];
            
            [[theValue(success) should] equal:theValue(NO)];
            [[error.localizedDescription should] equal:@"object was nil"];
        });
        
        it(@"should not be able to remove an object with no 'recordId' set", ^{
            NSMutableDictionary* user1 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"Matthias",@"name",@"123",@"bogudIdName", nil];
            
            NSError *error;
            BOOL success = [memStore remove:user1 error:&error];
            
            [[theValue(success) should] equal:theValue(NO)];
            [[error.localizedDescription should] equal:@"recordId not set"];
        });
        
        
        it(@"should perform filtering using an NSPredicate", ^{
            NSMutableDictionary *user1 = [@{@"id" : @"0",
                    @"name" : @"Robert",
                    @"city" : @"Boston",
                    @"salary" : @2100,
                    @"department" : @{@"name" : @"Software", @"address" : @"Cornwell"},
                    @"experience" : @[@{@"language" : @"Java", @"level" : @"advanced"},
                            @{@"language" : @"C", @"level" : @"advanced"}]
            } mutableCopy];

            NSMutableDictionary *user2 = [@{@"id" : @"1",
                    @"name" : @"David",
                    @"city" : @"New York",
                    @"salary" : @1400,
                    @"department" : @{@"name" : @"Hardware", @"address" : @"Cornwell"},
                    @"experience" : @[@{@"language" : @"Java", @"level" : @"advanced"},
                            @{@"language" : @"Python", @"level" : @"intermediate"}]
            } mutableCopy];

            NSMutableDictionary *user3 = [@{@"id" : @"2",
                    @"name" : @"Peter",
                    @"city" : @"New York",
                    @"salary" : @1800,
                    @"department" : @{@"name" : @"Software", @"address" : @"Branton"},
                    @"experience" : @[@{@"language" : @"Java", @"level" : @"advanced"},
                            @{@"language" : @"C", @"level" : @"intermediate"}]
            } mutableCopy];

            NSMutableDictionary *user4 = [@{@"id" : @"3",
                    @"name" : @"John",
                    @"city" : @"Boston",
                    @"salary" : @1700,
                    @"department" : @{@"name" : @"Software", @"address" : @"Norwell"},
                    @"experience" : @[@{@"language" : @"Java", @"level" : @"intermediate"},
                            @{@"language" : @"JavaScript", @"level" : @"advanced"}]
            } mutableCopy];

            NSMutableDictionary *user5 = [@{@"id" : @"4",
                    @"name" : @"Graham",
                    @"city" : @"Boston",
                    @"salary" : @2400,
                    @"department" : @{@"name" : @"Software", @"address" : @"Underwood"},
                    @"experience" : @[@{@"language" : @"Java", @"level" : @"advanced"},
                            @{@"language" : @"Python", @"level" : @"advanced"}]
            } mutableCopy];

            NSArray *users = @[user1, user2, user3, user4, user5];

            // save objects
            BOOL success = [memStore save:users error:nil];
            [[theValue(success) should] equal:theValue(YES)];

            NSPredicate *predicate;
            NSArray *results;

            // filter objects
            predicate = [NSPredicate
                    predicateWithFormat:@"city = 'Boston' AND department.name = 'Software' \
                              AND SUBQUERY(experience, $x, $x.language = 'Java' AND $x.level = 'advanced').@count > 0"];

            results = [memStore filter:predicate];

            // validate size
            [[results should] haveCountOf:2];

            // validate each object
            for (NSDictionary *user in results) {
                [[user[@"city"] should] equal:@"Boston"];
                [[user[@"department"][@"name"] should] equal:@"Software"];

                BOOL contains = [user[@"experience"] containsObject:@{@"language" : @"Java", @"level" : @"advanced"}];
                [[theValue(contains) should] equal:(theValue(YES))];
            }

            // retrieve only users with knowledge of BOTH Java AND Ruby (should be none)
            predicate = [NSPredicate
                    predicateWithFormat:@"SUBQUERY(experience, $x, $x.language IN {'Java', 'Ruby'}).@count = 2"];

            results = [memStore filter:predicate];

            // validate size
            [[results should] haveCountOf:0];

            // retrieve users with the specified salaries
            predicate = [NSPredicate
                    predicateWithFormat:@"department.name = 'Software' AND salary BETWEEN {1500, 2000}"];

            results = [memStore filter:predicate];

            // validate size
            [[results should] haveCountOf:2];

            // validate each object
            for (NSDictionary *user in results) {
                [[user[@"department"][@"name"] should] equal:@"Software"];
                [[theValue([user[@"salary"] intValue]) should] beBetween:theValue(1500) and:theValue(2000)];
            }
        });
    });
});

SPEC_END