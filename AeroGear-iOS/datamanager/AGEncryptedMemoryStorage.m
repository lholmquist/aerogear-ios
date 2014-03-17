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

#import "AGEncryptedMemoryStorage.h"
#import "AGEncryptionService.h"
#import "AGEncoder.h"

@implementation AGEncryptedMemoryStorage {

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
        // base inits:
        _type = @"ENCRYPTED_MEMORY";

        _data = [[NSMutableDictionary alloc] init];
        _recordId = storeConfig.recordId;
        _encryptionService = storeConfig.encryptionService;
        _encoder = [[AGPListEncoder alloc] initWithFormat:NSPropertyListBinaryFormat_v1_0];
    }
    
    return self;
}

- (NSArray *)readAll {
    NSMutableArray *list = [[NSMutableArray alloc] init];
    
    for (NSData *encryptedData in [_data allValues]) {
        NSData *decryptedData = [_encryptionService decrypt:encryptedData];

        id object = [_encoder decode:decryptedData error:nil];
        
        // fail fast if unable to deserialize caused by a mangled byte stream.
        if (!object)
            return nil;
        
        [list addObject:object];
    }
    
    return list;
}

- (id)read:(id)recordId {
    id retval;
    
    NSData *encryptedData = _data[recordId];
 
    if (encryptedData) {
        NSData *decryptedData = [_encryptionService decrypt:encryptedData];
        
        retval = [_encoder decode:decryptedData error:nil];
    }
    
    return retval;
}

- (NSArray *)filter:(NSPredicate *)predicate {
    return [self.readAll filteredArrayUsingPredicate:predicate];
}

- (BOOL)save:(id)data error:(NSError **)error {
    // fail fast if invalid data
    if (![_encoder isValid:data]) {
        if (error)
            *error = [NSError errorWithDomain:AGStoreErrorDomain
                                         code:0
                                     userInfo:@{NSLocalizedDescriptionKey: @"can't encode object for encryption!"}];
        // do nothing
        return NO;
    }

    // convenience to add objects inside an array
    if ([data isKindOfClass:[NSArray class]]) {
        for (id record in data)
            [self saveOne:record];

    } else {
        [self saveOne:data];
    }
    
    return YES;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"%@ [type=%@]", self.class, _type];
}

// =====================================================
// ================= utility methods  ==================
// =====================================================
- (void)save:(NSData *)encryptedData forKey:(NSString *)key {
    _data[key] = encryptedData;
}

- (NSData *)dump {
    return [_encoder encode:_data error:nil];
}

// =====================================================
// =========== private utility methods  ================
// =====================================================

- (void)saveOne:(NSMutableDictionary *)data {
    NSString *recordId = [AGBaseStorage getOrSetIdForData:data withIdentifier:_recordId];
    
    // convert to plist
    NSData *plist = [_encoder encode:data error:nil];
    
    // encrypt it
    NSData *encryptedData = [_encryptionService encrypt:plist];
    // set it
    _data[recordId] = encryptedData;
}

@end
