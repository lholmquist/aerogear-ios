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

#import "AGPropertyListStorage.h"
#import "AGMemoryStorage.h"
#import "AGStoreConfiguration.h"
#import "AGEncoder.h"

@implementation AGPropertyListStorage {
    NSURL *_file;
    
    id<AGEncoder> _encoder;
    
    AGMemoryStorage *_memStorage;    
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
        // base init:
        
        _type = storeConfig.type;
        
        if ([_type isEqualToString:@"JSON"])
            _encoder = [[AGJsonEncoder alloc] init];
        else  // if not specified use PLIST encoder
            _encoder = [[AGPListEncoder alloc] init];

        _memStorage = [[AGMemoryStorage alloc] initWithConfig:storeConfig];
        
        // extract file path
        _file = [AGBaseStorage storeURLWithName:storeConfig.name];
        
        // if plist file exists initialize store from it
        if ([[NSFileManager defaultManager] fileExistsAtPath:[_file path]]) {
            // load file
            NSData *data = [NSData dataWithContentsOfURL:_file];

            NSError *error;

            // decode structure
            NSArray *list = [_encoder decode:data error:&error];
           
            if (!error) {
                for (NSMutableDictionary *object in list) {
                    [_memStorage save:object error:nil];
                }
                
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

- (BOOL)save:(id)data error:(NSError **)error {
    // fail eager if not valid object
    if (![_encoder isValid:data]) {
        if (error)
            *error = [NSError errorWithDomain:AGStoreErrorDomain
                                         code:0
                                     userInfo:@{NSLocalizedDescriptionKey: @"not a valid format for the type specified"}];
        return NO;
    }
    
    return [_memStorage save:data error:error] && [self updateStore:error];
}

- (NSArray *)readAll {
    return [_memStorage readAll];
}

- (id)read:(id)recordId {
    return [_memStorage read:recordId];
}

- (NSArray *)filter:(NSPredicate *)predicate {
    return [_memStorage filter:predicate];
}

- (BOOL)reset:(NSError **)error {
    return [_memStorage reset:error] && [self updateStore:error];
}

- (BOOL)isEmpty {
    return [_memStorage isEmpty];
}

- (BOOL)remove:(id)record error:(NSError **)error {
    return [_memStorage remove:record error:error] && [self updateStore:error];
}

// =====================================================
// =========== private utility methods  ================
// =====================================================

- (BOOL)updateStore:(NSError **)error {
    NSData *plist = [_encoder encode:[_memStorage readAll] error:error];
    
    if (!plist)
        return NO;
    
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
