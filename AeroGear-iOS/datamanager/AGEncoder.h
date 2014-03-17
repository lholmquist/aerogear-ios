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
#import "AGEncryptionService.h"

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
- (instancetype) initWithFormat:(NSPropertyListFormat)format;
@end

/**
 An encoder backed by a NSJSONSerialization
 */
@interface AGJsonEncoder : NSObject <AGEncoder>
@end

/**
 Encode in PList with binary format and encrypt data.
 */
@interface AGEncryptedPListEncoder : NSObject <AGEncoder>
- (instancetype) initWithEncryptionService:(id<AGEncryptionService>)encryptionService;
@end
