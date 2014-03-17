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

#import "AGKeyManager.h"

#import "AGPasswordEncryptionServices.h"
#import "AGPassphraseEncryptionServices.h"

@implementation AGKeyManager {
    NSMutableDictionary *_keyServices;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _keyServices = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (instancetype)manager {
    return [[[self class] alloc] init];
}

- (id<AGEncryptionService>)keyService:(id<AGCryptoConfig>)config {
    id<AGEncryptionService> keyService;
    
    if ([config isKindOfClass:[AGKeyStoreCryptoConfig class]]) {
        keyService = [[AGPasswordEncryptionServices alloc] initWithConfig:config];
    } else if ([config isKindOfClass:[AGPassphraseCryptoConfig class]]) {
        keyService = [[AGPassphraseEncryptionServices alloc] initWithConfig:config];
    } else { // unsupported type
        return nil;
    }
    
    if (keyService)
        _keyServices[config.name] = keyService;
    
    return keyService;
}

- (id<AGEncryptionService>)remove:(NSString*) name {
    id<AGEncryptionService> service = [self keyServiceWithName:name];
    [_keyServices removeObjectForKey:name];
    
    return service;
}

- (id<AGEncryptionService>)keyServiceWithName:(NSString *)name {
    return _keyServices[name];
}

@end
