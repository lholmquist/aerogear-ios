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

@interface AGBaseStorage : NSObject

/**
 * Utility method to get an NSURL pointing to the file system
 * for the given filename.
 *
 * @param filename The filename.
 *
 * @return an NSURL pointing to the file.
 */
+ (NSURL *)storeURLWithName:(NSString *) filename;

/**
 * Utility method to get and set(if missing) an ID to an object. In
 * the case the ID is missing a generated UUID will be used.
 *
 * @return an NString with the ID of the object.
 */
+ (NSString *)getOrSetIdForData:(NSMutableDictionary *)data withIdentifier:(NSString *)identifier;

@end
