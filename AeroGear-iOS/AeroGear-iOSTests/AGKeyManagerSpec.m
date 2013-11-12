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
#import "AGKeyManager.h"
#import "AGKeyStoreCryptoConfig.h"

SPEC_BEGIN(AGKeyManagerSpec)

describe(@"AGKeyManagerSpec", ^{
    context(@"when newly created", ^{
        
        __block AGKeyManager *keyServices = nil;
        
        beforeEach(^{
            keyServices = [AGKeyManager manager];
        });
        
        it(@"should not be nil", ^{
            [keyServices shouldNotBeNil];
        });
        
        it(@"should allow add of an AGEncryptionService object", ^{
            AGKeyStoreCryptoConfig *config = [[AGKeyStoreCryptoConfig alloc] init];
            [config setAlias:@"alias"];
            [config setPassword:@"passphrase"];
            
            id<AGEncryptionService> service = [keyServices keyService:config];
            [(id)service shouldNotBeNil];
        });
        
        it(@"should _not_ add a nil AGEncryptionService object ", ^{
            AGKeyStoreCryptoConfig *config = [[AGKeyStoreCryptoConfig alloc] init];
            [config setAlias:@"alias"];
            [config setPassword:@"passphrase"];
            
            id<AGEncryptionService> service = [keyServices keyService:nil];
            [(id)service shouldBeNil];
        });

        it(@"should be able to add and remove an AGEncryptionService", ^{
            AGKeyStoreCryptoConfig *config = [[AGKeyStoreCryptoConfig alloc] init];
            [config setAlias:@"alias"];
            [config setPassword:@"passphrase"];
            
            id<AGEncryptionService> service;
            
            service = [keyServices keyService:config];
            [(id)service shouldNotBeNil];

            service = [keyServices keyServiceWithName:@"alias"];
            [(id)service shouldNotBeNil];
            
            [keyServices remove:@"alias"];
            service = [keyServices keyServiceWithName:@"alias"];
            [(id)service shouldBeNil];
        });
        
        it(@"should not remove a non existing AGEncryptionService", ^{
            AGKeyStoreCryptoConfig *config = [[AGKeyStoreCryptoConfig alloc] init];
            [config setAlias:@"alias"];
            [config setPassword:@"passphrase"];
            
            id<AGEncryptionService> service;
            
            service = [keyServices keyService:config];
            
            // remove non existing key service
            service = [keyServices remove:@"FOO"];
            [(id)service shouldBeNil];
            
            // should contain the first key service
            service = [keyServices keyServiceWithName:@"alias"];
            [(id)service shouldNotBeNil];
        });
    });
});

SPEC_END