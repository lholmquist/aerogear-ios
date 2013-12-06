//
//  AGEncoder.h
//  AeroGear-iOS
//
//  Created by Corinne Krych on 12/6/13.
//  Copyright (c) 2013 JBoss. All rights reserved.
//

#import <Foundation/Foundation.h>


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
- (id) init;
- (id) initWithFormat:(NSPropertyListFormat)format;
@end

/**
 An encoder backed by a NSJSONSerialization
 */
@interface AGJsonEncoder : NSObject <AGEncoder>
@end
