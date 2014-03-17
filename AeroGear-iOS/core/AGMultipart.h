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

/**
 * A Protocol that multipart object must implement.
 */
@protocol AGMultipart <NSObject>

/**
 * The name to be associated with this multipart object.
 */
@property (nonatomic, readonly, copy) NSString *name;

/**
 * The filename to be associated with this multipart object.
 */
@property (nonatomic, readonly, copy) NSString *fileName;

/**
 * The mimeType to be associated with this multipart object.
 */
@property (nonatomic, readonly, copy) NSString *mimeType;

@end

/**
 * A multipart object that it's contents are initialized
 * from a file on the file system.
 */
@interface AGFilePart : NSObject <AGMultipart>

@property (nonatomic, readonly) NSURL *fileURL;

/**
 * Initialize a multipart object that points to a file on the file system.
 *
 * @param fileURL The URL of the file whose contents will be added on the request.
 * @param name    The name to be associated with the specified data.
 */
- (instancetype)initWithFileURL:(NSURL *)fileURL
                           name:(NSString *)name;
@end

/**
 * A multipart object that it's contents are initialized
 * from an NSData object
 */
@interface AGFileDataPart :  NSObject <AGMultipart>

@property (nonatomic, readonly) NSData *data;

/**
 * Initialize a multipart object from an data object.
 *
 * @param data     The data whose contents will be added on the request.
 * @param name     The name to be associated with the specified data.
 * @param fileName The filename to be associated with the specified data.
 * @param mimeType The MIME type to be associated with the specified data.
 */
- (instancetype)initWithFileData:(NSData *)data
                            name:(NSString *)name
                        fileName:(NSString *)fileName
                        mimeType:(NSString *)mimeType;
@end

/**
 * A multipart object that it's contents are initialized
 * from a I/O stream.
 */
@interface AGStreamPart :  NSObject <AGMultipart>

@property (nonatomic, readonly) NSInputStream *inputStream;
@property (nonatomic, assign) NSUInteger length;

/**
 * Initialize a multipart object from an input stream.
 *
 * @param inputStream The inputstream whose contents will be added on the request.
 * @param name        The name to be associated with the specified data.
 * @param fileName    The filename to be associated with the specified data.
 * @param length      The total length of bytes of this input stream
 * @param mimeType    The MIME type to be associated with the specified data.
 */
- (instancetype)initWithInputStream:(NSInputStream *)inputStream
                               name:(NSString *)name
                           fileName:(NSString *)fileName
                             length:(NSUInteger)length
                           mimeType:(NSString *)mimeType;
@end