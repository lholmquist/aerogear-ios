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

/**
 * Provides a common interface around NSPropertyListSerialization and NSJSONSerialization
 * plist output formats. See AGPListEncoder class for plist encoding and AGJsonEncoder class for JSON
 * encoding.
 */
@protocol AGEncoder <NSObject>

/**
 * Returns an NSData object containing a given property list encoded in the respective 
 * serialization format.
 *
 * @param plist A valid property list object to be encoded.
 * @param error An error object containing details of why the encode failed.
 *
 * @return An NSData object containing plist encoded in the respective serialization format.
 */
- (NSData *)encode:(id)plist error:(NSError **)error;

/**
 * Creates and returns a property list from the specified data.
 *
 * @param data A collection (e.g. NSArray) which is being persisted.
 * @param error An error object containing details of why the decode failed.
 *
 * @return A property list object corresponding to the representation in data. If data is 
 *         not in a supported format, returns nil.
 */
- (id)decode:(NSData *)data error:(NSError **)error;

/**
 * Returns a Boolean value that indicates whether a given property list is valid for a given serialization format.
 *
 * @param plist A property list object.
 *
 * @return YES if plist is a valid property list in format format, otherwise NO.
 */
- (BOOL)isValid:(id)plist;

@end

/**
  An encoder backed by a NSPropertyListSerialization
 */
@interface AGPListEncoder : NSObject <AGEncoder>
@end

@implementation AGPListEncoder

- (NSData *)encode:(id)plist error:(NSError **)error {
    return [NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListXMLFormat_v1_0
                                                             options:0 error:error];
}

- (id)decode:(NSData *)data error:(NSError **)error {
    NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
    
    return [NSPropertyListSerialization propertyListWithData:data
                                                     options:NSPropertyListMutableContainersAndLeaves
                                                      format:&format error:error];
}

- (BOOL)isValid:(id)plist {
    return [NSPropertyListSerialization propertyList:plist isValidForFormat:NSPropertyListXMLFormat_v1_0];
}

@end

/**
  An encoder backed by a NSJSONSerialization
 */
@interface AGJsonEncoder : NSObject <AGEncoder>
@end

@implementation AGJsonEncoder

- (NSData *)encode:(id)plist error:(NSError **)error {
    return [NSJSONSerialization dataWithJSONObject:plist
                                    options:NSJSONWritingPrettyPrinted
                                      error:error];
}

- (id)decode:(NSData *)data error:(NSError **)error {
    id arr = [NSJSONSerialization JSONObjectWithData:data
                                    options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves
                                      error:error];
    
    // cater for iOS 5 returning an 'immutable' array when the size is empty
    if ([arr count] == 0 && ![arr isKindOfClass:[NSMutableArray class]])
        return nil;
    
    return arr;

}

- (BOOL)isValid:(id)plist {
    return [NSJSONSerialization isValidJSONObject:plist];
}

@end

@implementation AGPropertyListStorage {
    NSURL *_file;
    
    id<AGEncoder> _encoder;
    
    AGMemoryStorage *_memStorage;    
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
            NSMutableDictionary *list = [_encoder decode:data error:&error];
           
            if (!error) {
                [list enumerateKeysAndObjectsUsingBlock:^(id key, id encryptedData, BOOL *stop) {
                    [_memStorage save:encryptedData forKey:key];
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

- (BOOL)save:(id)data error:(NSError **)error {
    // fail eager if not valid object
    if (![_encoder isValid:data]) {
        if (error)
            *error = [NSError errorWithDomain:AGStoreErrorDomain
                                         code:0
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"not a valid format for the type specified", NSLocalizedDescriptionKey, nil]];
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
    NSData *plist = [_encoder encode:[_memStorage dump] error:error];
    
    if (!plist)
        return NO;
    
    // since 'NSData:writeToFile' fails silently, constuct an
    // error object to inform client
    if (![plist writeToURL:_file atomically:YES]) {
        if (error)
            *error = [NSError errorWithDomain:AGStoreErrorDomain
                                         code:0
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"an error occurred during save!",
                                               NSLocalizedDescriptionKey, nil]];
        return NO;
    }
    
    // if we reach here, file was saved successfully
    return YES;
}

@end
