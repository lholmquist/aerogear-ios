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
#import "AGEncryptedMemoryStorage.h"
#import "AGPasswordKeyServices.h"
#import "AGStoreConfiguration.h"

SPEC_BEGIN(AGEncryptedMemoryStorageSpec)

describe(@"AGEncryptedMemoryStorage", ^{
    context(@"when newly created", ^{
        
        // An encrypted 'in memory' storage object:
        __block AGEncryptedMemoryStorage* encMemStore = nil;
        // The Encryption service to use
        __block id<AGEncryptionService> encService = nil;
        
        beforeAll(^{
            AGKeyStoreCryptoConfig *config = [[AGKeyStoreCryptoConfig alloc] init];
            [config setAlias:@"alias"];
            [config setPassword:@"passphrase"];

            encService = [[AGPasswordKeyServices alloc] initWithConfig:config];
        });
        
        beforeEach(^{
            
            AGStoreConfiguration* config = [[AGStoreConfiguration alloc] init];
            [config setRecordId:@"id"];
            [config setEncryptionService:encService];

            encMemStore = [AGEncryptedMemoryStorage storeWithConfig:config];
        });        
        
        it(@"should not be nil", ^{
            [encMemStore shouldNotBeNil];
        });
        
        it(@"should save a single object ", ^{
            NSMutableDictionary* user1 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"Matthias",@"name",@"0",@"id", nil];
            
            BOOL success = [encMemStore save:user1 error:nil];
            [[theValue(success) should] equal:theValue(YES)];
            
        });
        
        it(@"should save a single object with no id set", ^{
            NSMutableDictionary* user = [NSMutableDictionary
                                         dictionaryWithObjectsAndKeys:@"Matthias",@"name", nil];
            
            BOOL success = [encMemStore save:user error:nil];
            [[theValue(success) should] equal:theValue(YES)];
            
            [[user valueForKey:@"id"] shouldNotBeNil];
            
        });
        
        it(@"should read an object _after_ storing it", ^{
            NSMutableDictionary* user = [NSMutableDictionary
                                         dictionaryWithObjectsAndKeys:@"Matthias",@"name",@"0",@"id", nil];
            
            // store it
            BOOL success = [encMemStore save:user error:nil];
            [[theValue(success) should] equal:theValue(YES)];
            
            // read it
            NSMutableDictionary* object = [encMemStore read:@"0"];
            [[[object objectForKey:@"name"] should] equal:@"Matthias"];
        });
        
        it(@"should read an object _after_ storing it (using readAll)", ^{
            NSMutableDictionary* user1 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"Matthias",@"name",@"0815",@"id", nil];
            
            BOOL success = [encMemStore save:user1 error:nil];
            [[theValue(success) should] equal:theValue(YES)];
            
            // read it
            NSArray* objects = [encMemStore readAll];
            
            [[objects should] haveCountOf:1];
            [[objects should] containObjects:user1, nil];
            
            [[[[objects objectAtIndex:(NSUInteger)0] objectForKey:@"name"] should] equal:@"Matthias"];
            [[[[objects objectAtIndex:(NSUInteger)0] objectForKey:@"id"] should] equal:@"0815"];
        });
        
        it(@"should read nothing out of an empty store", ^{
            // read it
            NSArray* objects = [encMemStore readAll];
            
            [[objects should] beEmpty];
        });
        
        it(@"should read nothing out of an empty store", ^{
            // read it, should be empty
            [[theValue([encMemStore isEmpty]) should] equal:theValue(YES)];
            
        });
        
        it(@"should read not object out of an empty store", ^{
            NSMutableDictionary *object = [encMemStore read:@"someId"];
            
            [object shouldBeNil];
        });
        
        it(@"should read and save multiple objects", ^{
            NSMutableDictionary* user1 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"Matthias",@"name",@"123",@"id", nil];
            NSMutableDictionary* user2 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"abstractj",@"name",@"456",@"id", nil];
            NSMutableDictionary* user3 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"qmx",@"name",@"5",@"id", nil];
            
            NSArray* users = [NSArray arrayWithObjects:user1, user2, user3, nil];
            
            // store it
            BOOL success = [encMemStore save:users error:nil];
            [[theValue(success) should] equal:theValue(YES)];
            
            // read it
            NSArray* objects = [encMemStore readAll];
            
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
            
            NSArray* users = [NSArray arrayWithObjects:user1, user2, user3, nil];
            
            // store it
            [encMemStore save:users error:nil];
            
            // check if empty:
            [[theValue([encMemStore isEmpty]) should] equal:theValue(NO)];
        });
        
        it(@"should read nothing after reset", ^{
            NSMutableDictionary* user1 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"Matthias",@"name",@"123",@"id", nil];
            NSMutableDictionary* user2 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"abstractj",@"name",@"456",@"id", nil];
            NSMutableDictionary* user3 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"qmx",@"name",@"5",@"id", nil];
            
            NSArray* users = [NSArray arrayWithObjects:user1, user2, user3, nil];
            
            NSArray* objects;
            BOOL success;
            
            // store it
            success = [encMemStore save:users error:nil];
            [[theValue(success) should] equal:theValue(YES)];
            
            // read it
            objects = [encMemStore readAll];
            [[objects should] haveCountOf:(NSUInteger)3];
            [[objects should] containObjects:user1, nil];
            [[objects should] containObjects:user2, nil];
            [[objects should] containObjects:user3, nil];
            
            
            success = [encMemStore reset:nil];
            [[theValue(success) should] equal:theValue(YES)];
            
            // read from the empty store...
            objects = [encMemStore readAll];
            
            [[objects should] haveCountOf:(NSUInteger)0];
        });
        
        it(@"should be able to do bunch of read, save, reset operations", ^{
            NSMutableDictionary* user1 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"Matthias",@"name",@"123",@"id", nil];
            NSMutableDictionary* user2 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"abstractj",@"name",@"456",@"id", nil];
            NSMutableDictionary* user3 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"qmx",@"name",@"5",@"id", nil];
            
            NSArray* users = [NSArray arrayWithObjects:user1, user2, user3, nil];
            
            NSArray* objects;
            
            BOOL success;
            
            // store it
            success = [encMemStore save:users error:nil];
            [[theValue(success) should] equal:theValue(YES)];
            
            // read it
            objects = [encMemStore readAll];
            [[objects should] haveCountOf:(NSUInteger)3];
            [[objects should] containObjects:user1, nil];
            [[objects should] containObjects:user2, nil];
            [[objects should] containObjects:user3, nil];
            
            success = [encMemStore reset:nil];
            
            // read from the empty store...
            objects = [encMemStore readAll];
            [[objects should] haveCountOf:(NSUInteger)0];
            
            // store it again...
            success = [encMemStore save:users error:nil];
            [[theValue(success) should] equal:theValue(YES)];
            
            // read it again ...
            objects = [encMemStore readAll];
            [[objects should] haveCountOf:(NSUInteger)3];
            [[objects should] containObjects:user1, nil];
            [[objects should] containObjects:user2, nil];
            [[objects should] containObjects:user3, nil];
        });
        
        it(@"should not be able to save a non-dictionary object", ^{
            // an arbitary object instead of an nsdictionary
            NSSet *user1 = [NSSet setWithObjects:@"Matthias",@"name",@"1",@"id", nil];
            NSError *error;
            
            BOOL success = [encMemStore save:user1 error:&error];
            
            [[theValue(success) should] equal:theValue(NO)];
        });
        
        it(@"should not be able to save a non-dictionary object contained inside an NSArray", ^{
            // an arbitary object instead of an nsdictionary
            NSSet *user1 = [NSSet setWithObjects:@"Matthias",@"name",@"1",@"id", nil];
            
            // wrap it inside an array
            NSMutableArray *arr = [NSMutableArray arrayWithObjects:user1, nil];
            NSError *error;
            
            BOOL success = [encMemStore save:arr error:&error];
            
            [[theValue(success) should] equal:theValue(NO)];
        });
        
        it(@"should not read a remove object", ^{
            NSMutableDictionary* user1 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"Matthias",@"name",@"0",@"id", nil];
            
            BOOL success;
            
            success = [encMemStore save:user1 error:nil];
            [[theValue(success) should] equal:theValue(YES)];
            
            // read it
            NSMutableDictionary *object = [encMemStore read:@"0"];
            [[[object objectForKey:@"name"] should] equal:@"Matthias"];
            
            // remove the above user:
            success = [encMemStore remove:user1 error:nil];
            [[theValue(success) should] equal:theValue(YES)];
            
            // read from the empty store...
            NSArray* objects = [encMemStore readAll];
            [[objects should] haveCountOf:(NSUInteger)0];
        });
        
        it(@"should not remove non-existing object", ^{
            NSMutableDictionary* user1 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"Matthias",@"name",@"0",@"id", nil];
            
            BOOL success;
            
            success = [encMemStore save:user1 error:nil];
            [[theValue(success) should] equal:theValue(YES)];
            
            // read it
            NSMutableDictionary *object = [encMemStore read:@"0"];
            [[[object objectForKey:@"name"] should] equal:@"Matthias"];
            
            NSMutableDictionary* user2 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"Matthias",@"name",@"1",@"id", nil];
            
            // remove the user with the id '1' (not existing):
            success = [encMemStore remove:user2 error:nil];
            [[theValue(success) should] equal:theValue(NO)];
            
            // should contain the first object
            NSArray* objects = [encMemStore readAll];
            
            [[objects should] haveCountOf:1];
        });
        
        it(@"should not be able to remove a nil object", ^{
            NSError *error;
            BOOL success;
            
            success = [encMemStore remove:nil error:&error];
            
            [[theValue(success) should] equal:theValue(NO)];
            
            success = [encMemStore remove:[NSNull null] error:&error];
            
            [[theValue(success) should] equal:theValue(NO)];
        });
        
        it(@"should not be able to remove an object with no 'recordId' set", ^{
            NSMutableDictionary* user1 = [NSMutableDictionary
                                          dictionaryWithObjectsAndKeys:@"Matthias",@"name",@"123",@"bogudIdName", nil];
            
            NSError *error;
            BOOL success = [encMemStore remove:user1 error:&error];
            
            [[theValue(success) should] equal:theValue(NO)];
        });
        
        it(@"should perform filtering using an NSPredicate", ^{
            NSMutableDictionary *user1 = [@{@"id" : @"0",
                                            @"name" : @"Robert",
                                            @"city" : @"Boston",
                                            @"salary" : [NSNumber numberWithInt:2100],
                                            @"department" : @{@"name" : @"Software", @"address" : @"Cornwell"},
                                            @"experience" : @[@{@"language" : @"Java", @"level" : @"advanced"},
                                                              @{@"language" : @"C", @"level" : @"advanced"}]
                                            } mutableCopy];
            
            NSMutableDictionary *user2 = [@{@"id" : @"1",
                                            @"name" : @"David",
                                            @"city" : @"New York",
                                            @"salary" : [NSNumber numberWithInt:1400],
                                            @"department" : @{@"name" : @"Hardware", @"address" : @"Cornwell"},
                                            @"experience" : @[@{@"language" : @"Java", @"level" : @"advanced"},
                                                              @{@"language" : @"Python", @"level" : @"intermediate"}]
                                            } mutableCopy];
            
            NSMutableDictionary *user3 = [@{@"id" : @"2",
                                            @"name" : @"Peter",
                                            @"city" : @"New York",
                                            @"salary" : [NSNumber numberWithInt:1800],
                                            @"department" : @{@"name" : @"Software", @"address" : @"Branton"},
                                            @"experience" : @[@{@"language" : @"Java", @"level" : @"advanced"},
                                                              @{@"language" : @"C", @"level" : @"intermediate"}]
                                            } mutableCopy];
            
            NSMutableDictionary *user4 = [@{@"id" : @"3",
                                            @"name" : @"John",
                                            @"city" : @"Boston",
                                            @"salary" : [NSNumber numberWithInt:1700],
                                            @"department" : @{@"name" : @"Software", @"address" : @"Norwell"},
                                            @"experience" : @[@{@"language" : @"Java", @"level" : @"intermediate"},
                                                              @{@"language" : @"JavaScript", @"level" : @"advanced"}]
                                            } mutableCopy];
            
            NSMutableDictionary *user5 = [@{@"id" : @"4",
                                            @"name" : @"Graham",
                                            @"city" : @"Boston",
                                            @"salary" : [NSNumber numberWithInt:2400],
                                            @"department" : @{@"name" : @"Software", @"address" : @"Underwood"},
                                            @"experience" : @[@{@"language" : @"Java", @"level" : @"advanced"},
                                                              @{@"language" : @"Python", @"level" : @"advanced"}]
                                            } mutableCopy];
            
            NSArray *users = @[user1, user2, user3, user4, user5];
            
            // save objects
            BOOL success = [encMemStore save:users error:nil];
            [[theValue(success) should] equal:theValue(YES)];
            
            NSPredicate *predicate;
            NSArray *results;
            
            // filter objects
            predicate = [NSPredicate
                         predicateWithFormat:@"city = 'Boston' AND department.name = 'Software' \
                         AND SUBQUERY(experience, $x, $x.language = 'Java' AND $x.level = 'advanced').@count > 0"];
            
            results = [encMemStore filter:predicate];
            
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
            
            results = [encMemStore filter:predicate];
            
            // validate size
            [[results should] haveCountOf:0];
            
            // retrieve users with the specified salaries
            predicate = [NSPredicate
                         predicateWithFormat:@"department.name = 'Software' AND salary BETWEEN {1500, 2000}"];
            
            results = [encMemStore filter:predicate];
            
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