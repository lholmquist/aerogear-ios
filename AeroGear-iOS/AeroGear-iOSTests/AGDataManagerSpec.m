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
#import "AGDataManager.h"

SPEC_BEGIN(AGDataManagerSpec)

describe(@"AGDataManager", ^{
    context(@"when newly created", ^{

        __block AGDataManager *manager = nil;

        beforeEach(^{
            manager = [AGDataManager manager];
        });

        it(@"should not be nil", ^{
            [manager shouldNotBeNil];
        });
    });

    context(@"when adding a new store", ^{

        __block AGDataManager *manager = nil;

        beforeEach(^{
            manager = [AGDataManager manager];
        });

        it(@"should have a default type if not specified", ^{
            id<AGStore> store = [manager store:^(id<AGStoreConfig> config) {
                [config setName:@"tasks"];
            }];

            [(id)store shouldNotBeNil];

            [[store.type should] equal:@"MEMORY"];
        });

        it(@"should not allow an invalid type", ^{
            id<AGStore> store = [manager store:^(id<AGStoreConfig> config) {
                [config setName:@"tasks"];
                [config setType:@"INVALID"];
            }];

            [(id)store shouldBeNil];
        });
    });
    
    context(@"when adding a new store of type SQLITE", ^{
        
        __block AGDataManager *manager = nil;
        
        beforeEach(^{
            manager = [AGDataManager manager];
        });
        
        it(@"should have a SQLITE type", ^{
            id<AGStore> store = [manager store:^(id<AGStoreConfig> config) {
                [config setName:@"tasks"];
                [config setType:@"SQLITE"];
            }];
            
            [(id)store shouldNotBeNil];
            
            [[store.type should] equal:@"SQLITE"];
        });
        
    });

    context(@"when adding a new store of type ENCRYPTED_SQLITE", ^{

        __block AGDataManager *manager = nil;

        beforeEach(^{
            manager = [AGDataManager manager];
        });

        it(@"should have a SQLITE type", ^{
            id<AGStore> store = [manager store:^(id<AGStoreConfig> config) {
                [config setName:@"tasks"];
                [config setType:@"ENCRYPTED_SQLITE"];
            }];

            [(id)store shouldNotBeNil];

            [[store.type should] equal:@"ENCRYPTED_SQLITE"];
        });

    });

    context(@"when adding and removing stores", ^{

        __block AGDataManager *manager = nil;

        beforeEach(^{
            manager = [AGDataManager manager];
        });

        it(@"should successfully remove previously added stores", ^{
            id<AGStore> taskStore = [manager store:^(id<AGStoreConfig> config) {
                [config setName:@"tasks"];
            }];

            [(id)taskStore shouldNotBeNil];

            id<AGStore> tagStore = [manager store:^(id<AGStoreConfig> config) {
                [config setName:@"projects"];
            }];

            [(id)tagStore shouldNotBeNil];

            // look em up:
            [(id)[manager storeWithName:@"tasks"] shouldNotBeNil];
            [(id)[manager storeWithName:@"projects"] shouldNotBeNil];

            // remove it
            [manager remove:@"tasks"];
            // look it up:
            [(id)[manager storeWithName:@"tasks"] shouldBeNil];

            // remove it
            [manager remove:@"projects"];
            // look it up:
            [(id)[manager storeWithName:@"projects"] shouldBeNil];
        });

        it(@"should not remove a non existing store", ^{
            id<AGStore> store = [manager store:^(id<AGStoreConfig> config) {
                [config setName:@"tasks"];
            }];

            [(id)store shouldNotBeNil];

            // remove non existing store
            id<AGStore> fooStore = [manager remove:@"FOO"];
            [(id)fooStore shouldBeNil];

            // should contain the first store
            store = [manager storeWithName:@"tasks"];
            [(id)store shouldNotBeNil];
        });

        it(@"should not fail when you lookup a non existing store", ^{
            // look up a non existing store
            id<AGStore> fooStore = [manager storeWithName:@"FOO"];
            [(id)fooStore shouldBeNil];
        });
    });
});

SPEC_END