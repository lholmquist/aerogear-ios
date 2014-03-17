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

@implementation AGMemoryStorage

@synthesize type = _type;

// ==============================================
// ======== 'factory' and 'init' section ========
// ==============================================

+(instancetype) storeWithConfig:(id<AGStoreConfig>) storeConfig {
    return [[[self class] alloc] initWithConfig:storeConfig];
}

-(instancetype) initWithConfig:(id<AGStoreConfig>) storeConfig {
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
    return _data[recordId];
}

- (NSArray *)filter:(NSPredicate *)predicate {
    return [[_data allValues] filteredArrayUsingPredicate:predicate];
}

- (BOOL)save:(id)data error:(NSError **)error {
    // convenience to add objects inside an array
    if ([data isKindOfClass:[NSArray class]]) {
        // fail fast if the array contains non-dictionary objects
        for (id record in data) {
            if (![record isKindOfClass:[NSDictionary class]]) {
                if (error)
                    *error = [NSError errorWithDomain:AGStoreErrorDomain
                                                 code:0
                                             userInfo:@{NSLocalizedDescriptionKey: @"array contains non-dictionary objects!"}];
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
                                     userInfo:@{NSLocalizedDescriptionKey: @"dictionary objects are supported only"}];
        return  NO;
    }
    
    return YES;
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
                                     userInfo:@{NSLocalizedDescriptionKey: @"object was nil"}];
        // do nothing
        return NO;
    }
    
    id key = record[_recordId];

    if (!key || [key isKindOfClass:[NSNull class]]) {
        if (error)
            *error = [NSError errorWithDomain:AGStoreErrorDomain
                                         code:0
                                     userInfo:@{NSLocalizedDescriptionKey: @"recordId not set"}];
        // do nothing
        return NO;
    }

    // if the object exists
    if (_data[key]) {
        // remove it
        [_data removeObjectForKey:key];
        
        return YES;
    }
    
    return NO;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"%@ [type=%@]", self.class, _type];
}

// =====================================================
// =========== private utility methods  ================
// =====================================================

- (void)saveOne:(NSMutableDictionary *)data {
    id recordId = [AGBaseStorage getOrSetIdForData:data withIdentifier:_recordId];
    
    _data[recordId] = data;
}

@end
