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

#import "AGPasswordEncryptionServices.h"

#import <AGRandomGenerator.h>
#import <AGSecretBox.h>

@implementation AGPasswordEncryptionServices {
    NSString *_passKeyTag;
    NSString *_symmetricKeyTag;
}

- (instancetype)initWithConfig:(AGKeyStoreCryptoConfig *)config {
    self = [super init];

    // TODO
    // once https://issues.jboss.org/browse/AGIOS-103
    // is in place, it will be refactored to use it
    if (self) {
        // setup key tags used to access keychain
        _passKeyTag = [config.alias stringByAppendingString:@".password"];
        _symmetricKeyTag = [config.alias stringByAppendingString:@".symmetric"];

        NSMutableDictionary *query;
        CFTypeRef data;
        OSStatus status;
        NSData *key;
        
        // setup query for password
        query = [self keyChainDictionaryForPasswordClass];
        
        query[(__bridge id)kSecAttrService] = config.alias;
        query[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
        query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
        
        status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &data);
        
        if (status == errSecSuccess) { // password entry found
            // retrieve value
            NSData *password = [NSData dataWithData:(__bridge NSData *)data];
            if (data) CFRelease(data);
            
            // can't proceed if passwords don't match
            if (![password isEqualToData:[config.password dataUsingEncoding:NSUTF8StringEncoding]])
                return nil;
            
            // good to go, time to extract key..

            // setup query for key
            query = [self keyChainDictionaryForKeyClass];
            
            query[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
            query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

            // Get the key bits.
          	status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&data);
            
            if (status == errSecSuccess) { // key found
                // extract it
                key = [NSData dataWithData:(__bridge NSData *)data];

                if (data) CFRelease(data);
            }
            
        } else if (status == errSecItemNotFound) {
            // step 1: add password to keychain
            query = [self keyChainDictionaryForPasswordClass];
            
            query[(__bridge id)kSecAttrService] = config.alias;

            NSData *data = [config.password dataUsingEncoding:NSUTF8StringEncoding];
            query[(__bridge id)kSecValueData] = data;
            
            // add it
            status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
            
            // step 2: generate and add symmetric key
            query = [self keyChainDictionaryForKeyClass];

            query[(__bridge id)kSecAttrKeySizeInBits] = @16U;
            query[(__bridge id)kSecAttrEffectiveKeySize] = @16U;
            query[(__bridge id)kSecAttrCanEncrypt] = (__bridge id)kCFBooleanTrue;
            query[(__bridge id)kSecAttrCanDecrypt] = (__bridge id)kCFBooleanTrue;
            query[(__bridge id)kSecAttrCanDerive] = (__bridge id)kCFBooleanFalse;
            query[(__bridge id)kSecAttrCanSign] = (__bridge id)kCFBooleanFalse;
            query[(__bridge id)kSecAttrCanVerify] = (__bridge id)kCFBooleanFalse;
            query[(__bridge id)kSecAttrCanWrap] = (__bridge id)kCFBooleanFalse;
            query[(__bridge id)kSecAttrCanUnwrap] = (__bridge id)kCFBooleanFalse;
            
            // generate key
            key = [AGRandomGenerator randomBytes:16];
            query[(__bridge id)kSecValueData] = key;
            
            // add it
            status = SecItemAdd((__bridge CFDictionaryRef) query, NULL);
        }
        
        // initialize cryptobox
        _secretBox = [[AGSecretBox alloc] initWithKey:key];
    }
    
    return self;
}

#pragma mark - private helper methods

- (NSMutableDictionary *)keyChainDictionaryForPasswordClass {
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
    
    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    query[(__bridge id)kSecAttrGeneric] = [_passKeyTag dataUsingEncoding:NSUTF8StringEncoding];
    query[(__bridge id)kSecAttrAccount] = [_passKeyTag dataUsingEncoding:NSUTF8StringEncoding];

    return query;
}

- (NSMutableDictionary *)keyChainDictionaryForKeyClass {
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
    
    query[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;
    query[(__bridge id)kSecAttrApplicationTag] = _symmetricKeyTag;
    
    return query;
}

@end
