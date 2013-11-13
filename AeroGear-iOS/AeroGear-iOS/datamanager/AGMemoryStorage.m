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

#import "AGMemoryStorage.h"
#import "AGStoreConfiguration.h"

@implementation AGMemoryStorage {
    NSMutableDictionary *_data;
    NSString *_recordId;
}

@synthesize type = _type;

// ==============================================
// ======== 'factory' and 'init' section ========
// ==============================================

+(id) storeWithConfig:(id<AGStoreConfig>) storeConfig {
    return [[self alloc] initWithConfig:storeConfig];
}

-(id) initWithConfig:(id<AGStoreConfig>) storeConfig {
    self = [super init];
    if (self) {
        // base inits:
        _type = @"MEMORY";
      
        _data = [[NSMutableDictionary alloc] init];
        _recordId = storeConfig.recordId;
    }
    
    return self;
}

// =====================================================
// ======== public API (AGStore) ========
// =====================================================

- (NSArray *)readAll {
    return [_data allValues] ;
}

- (id)read:(id)recordId {
    return [_data objectForKey:recordId];
}

- (NSArray *)filter:(NSPredicate *)predicate {
    return [[_data allValues] filteredArrayUsingPredicate:predicate];
}

- (BOOL)save:(id)data error:(NSError **)error {
    // convinience to add objects inside an array
    if ([data isKindOfClass:[NSArray class]]) {
        // fail fast if the array contains non-dictionary objects
        for (id record in data) {
            if (![record isKindOfClass:[NSDictionary class]]) {
                if (error)
                    *error = [NSError errorWithDomain:AGStoreErrorDomain
                                                 code:0
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"array contains non-dictionary objects!", NSLocalizedDescriptionKey, nil]];
                // do nothing
                return NO;
            }
        }
        
        // traverse and save each
        for (id record in data)
            [self saveOne:record];
        
    } else if([data isKindOfClass:[NSDictionary class]]) {
        // single obj
        [self saveOne:data];

    } else { // not a dictionary, fail back
        if (error)
            *error = [NSError errorWithDomain:AGStoreErrorDomain
                                         code:0
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"dictionary objects are supported only", NSLocalizedDescriptionKey, nil]];
        return  NO;
    }
    
    return YES;
}

- (void)save:(id)value forKey:(NSString*)key {
    [_data setObject:value forKey:key];
}

- (BOOL)reset:(NSError **)error {
    [_data removeAllObjects];
    
    return YES;
}

- (BOOL)isEmpty {
    return [_data count] == 0;    
}

- (BOOL)remove:(id)record error:(NSError **)error {
    if (record == nil || [record isKindOfClass:[NSNull class]]) {
        if (error)
            *error = [NSError errorWithDomain:AGStoreErrorDomain
                                         code:0
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"object was nil", NSLocalizedDescriptionKey, nil]];
        // do nothing
        return NO;
    }
    
    id key = [record objectForKey:_recordId];

    if (!key || [key isKindOfClass:[NSNull class]]) {
        if (error)
            *error = [NSError errorWithDomain:AGStoreErrorDomain
                                         code:0
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"recordId not set", NSLocalizedDescriptionKey, nil]];
        // do nothing
        return NO;
    }

    // if the object exists
    if ([_data objectForKey:key]) {
        // remove it
        [_data removeObjectForKey:key];
        
        return YES;
    }
    
    return NO;
}

- (NSDictionary *)dump {
    return _data;
}

- (NSString *)getOrSetIdForData:(NSMutableDictionary *)data {
    id recordId = [data objectForKey:_recordId];
    
    // if the object hasn't set a recordId property
    if (!recordId) {
        //generate a UUID to be used instead
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        NSString *uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
        CFRelease(uuid);
        
        recordId = uuidStr;
        // set the generated ID for the newly object
        [data setValue:recordId forKey:_recordId];
    }
    
    return recordId;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"%@ [type=%@]", self.class, _type];
}

// =====================================================
// =========== private utility methods  ================
// =====================================================

- (void)saveOne:(NSMutableDictionary *)data {
    id recordId = [self getOrSetIdForData:data];
    
    [_data setObject:data forKey:recordId];
}

@end
