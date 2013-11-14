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

static NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;

@implementation AGEncryptedMemoryStorage {

    id<AGEncryptionService> _encryptionService;
}

@synthesize type = _type;

// ==============================================
// ======== 'factory' and 'init' section ========
// ==============================================

+ (id)storeWithConfig:(id<AGStoreConfig>) storeConfig {
    return [[self alloc] initWithConfig:storeConfig];
}

- (id)initWithConfig:(id<AGStoreConfig>) storeConfig {
    self = [super init];
    if (self) {
        // base inits:
        _type = @"ENCRYPTED_MEMORY";

        _data = [[NSMutableDictionary alloc] init];
        _recordId = storeConfig.recordId;
        _encryptionService = storeConfig.encryptionService;
    }
    
    return self;
}

- (NSArray *)readAll {
    NSMutableArray *list = [[NSMutableArray alloc] init];
    
    for (NSData *encryptedData in [_data allValues]) {
        NSData *decryptedData = [_encryptionService decrypt:encryptedData];

        id object =  [NSPropertyListSerialization propertyListWithData:decryptedData
                                                               options:NSPropertyListMutableContainersAndLeaves
                                                                format:&format error:nil];
        [list addObject:object];
    }
    
    return list;
}

- (id)read:(id)recordId {
    id retval;
    
    NSData *encryptedData = [_data objectForKey:recordId];
 
    if (encryptedData) {
        NSData *decryptedData = [_encryptionService decrypt:encryptedData];
        
        retval =  [NSPropertyListSerialization propertyListWithData:decryptedData
                                                            options:NSPropertyListMutableContainersAndLeaves
                                                             format:&format error:nil];
    }
    
    return retval;
}

- (NSArray *)filter:(NSPredicate *)predicate {
    return [self.readAll filteredArrayUsingPredicate:predicate];
}

- (BOOL)save:(id)data error:(NSError **)error {
    // fail fast if invalid data
    if (![NSPropertyListSerialization propertyList:data isValidForFormat:NSPropertyListBinaryFormat_v1_0]) {
        if (error)
            *error = [NSError errorWithDomain:AGStoreErrorDomain
                                         code:0
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"can't encode object for encryption!",
                                               NSLocalizedDescriptionKey, nil]];
        // do nothing
        return NO;
    }

    // convinience to add objects inside an array
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
    [_data setObject:encryptedData forKey:key];
}

- (NSData *)dump {
    return [NSPropertyListSerialization dataWithPropertyList:_data
                                                      format:NSPropertyListBinaryFormat_v1_0
                                                     options:0 error:nil];
}

// =====================================================
// =========== private utility methods  ================
// =====================================================

- (void)saveOne:(NSMutableDictionary *)data {
    NSString *recordId = [AGBaseStorage getOrSetIdForData:data withIdentifier:_recordId];
    
    // convert to plist
    NSData *plist = [NSPropertyListSerialization dataWithPropertyList:data
                                               format:NSPropertyListBinaryFormat_v1_0
                                              options:0 error:nil];
    
    // encrypt it
    NSData *encryptedData = [_encryptionService encrypt:plist];
    // set it
    [_data setObject:encryptedData forKey:recordId];
}

@end
