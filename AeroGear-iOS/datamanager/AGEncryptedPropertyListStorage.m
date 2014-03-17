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

#import "AGEncryptedPropertyListStorage.h"
#import "AGEncryptedMemoryStorage.h"
#import "AGEncoder.h"

@implementation AGEncryptedPropertyListStorage {
    NSURL *_file;
    
    AGEncryptedMemoryStorage *_encStorage;
    id<AGEncryptionService> _encryptionService;
    id<AGEncoder> _encoder;
}

@synthesize type = _type;

// ==============================================
// ======== 'factory' and 'init' section ========
// ==============================================

+ (instancetype)storeWithConfig:(id<AGStoreConfig>) storeConfig {
    return [[[self class] alloc] initWithConfig:storeConfig];
}

- (instancetype)initWithConfig:(id<AGStoreConfig>) storeConfig {
    self = [super init];
    if (self) {
        _type = @"ENCRYPTED_PLIST";
        
        _encStorage = [[AGEncryptedMemoryStorage alloc] initWithConfig:storeConfig];
        _encryptionService = storeConfig.encryptionService;
        
        // extract file path
        _file = [AGBaseStorage storeURLWithName:storeConfig.name];
        
        // if plist file exists initialize store from it
        if ([[NSFileManager defaultManager] fileExistsAtPath:[_file path]]) {
            // load file
            NSData *data = [NSData dataWithContentsOfURL:_file];
            
            NSError *error;
            
            // decode structure
            _encoder = [[AGPListEncoder alloc] initWithFormat:NSPropertyListBinaryFormat_v1_0];
            NSDictionary *plist = [_encoder decode:data error:&error];
            if (!error) {
                [plist enumerateKeysAndObjectsUsingBlock:^(id key, id encryptedData, BOOL *stop) {
                    [_encStorage save:encryptedData forKey:key];
                }];
                
            } else { // log the error
                NSLog(@"%@ %@: %@", [self class], NSStringFromSelector(_cmd), error);
            }
        }
    }
    
    return self;
}

// =====================================================
// ======== public API (AGStore) ========
// =====================================================

- (NSArray *)readAll {
    return [_encStorage readAll];
}

- (id)read:(id)recordId {
    return [_encStorage read:recordId];
}

- (NSArray *)filter:(NSPredicate *)predicate {
    return [_encStorage filter:predicate];
}

- (BOOL)save:(id)data error:(NSError **)error {
    return [_encStorage save:data error:error] && [self updateStore:error];
}

- (BOOL)reset:(NSError **)error {
    return [_encStorage reset:error] && [self updateStore:error];
}

- (BOOL)isEmpty {
    return [_encStorage isEmpty];
}

- (BOOL)remove:(id)record error:(NSError **)error {
    return [_encStorage remove:record error:error]  && [self updateStore:error];
}

- (NSString *)description {
    return [NSString stringWithFormat: @"%@ [type=%@]", self.class, _type];
}

// =====================================================
// =========== private utility methods  ================
// =====================================================

- (BOOL)updateStore:(NSError **)error {
    NSData *plist = [_encStorage dump];
    
    // since 'NSData:writeToFile' fails silently, construct an
    // error object to inform client
    if (![plist writeToURL:_file atomically:YES]) {
        if (error)
            *error = [NSError errorWithDomain:AGStoreErrorDomain
                                         code:0
                                     userInfo:@{NSLocalizedDescriptionKey: @"an error occurred during save!"}];
        return NO;
    }
    
    // if we reach here, file was saved successfully
    return YES;
}

@end
