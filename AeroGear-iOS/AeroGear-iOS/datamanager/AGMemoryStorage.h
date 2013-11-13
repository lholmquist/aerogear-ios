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

#import <Foundation/Foundation.h>
#import "AGBaseStorage.h"
#import "AGStore.h"
#import "AGStoreConfiguration.h"

/**
 An internal AGStore implementation that uses "in-memory" storage.
 
 *IMPORTANT:* Users are not required to instantiate this class directly, instead an instance of this class is returned automatically when an DataStore with default configuration is constructed or with the _type_ config option set to _"MEMORY"_. See AGDataManager and AGStore class documentation for more information.
 
 */
@interface AGMemoryStorage : AGBaseStorage <AGStore>

/**
 * internal utility method to set an object directly on the store
 *
 * @param value The object to be persisted.
 * @param key The key under this object will bound to.
 *
 */
- (void)save:(id)value forKey:(NSString *)key;

/**
 * internal utility method to dump the contents of this memory storage
 *
 * @return a dump of the contents of this memory storage.
 */
- (NSDictionary *)dump;

/**
 * internal utility method to get and set(if missing) an ID to an object. In
 * the case the ID is missing a generated UUID will be used.
 *
 * @return an NString with the ID of the object.
 */
- (NSString *)getOrSetIdForData:(NSMutableDictionary *)data;

@end
