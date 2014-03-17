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

#import "AGMultipart.h"

@implementation AGFilePart

@synthesize name =_name;
@synthesize fileName = _fileName;
@synthesize mimeType = _mimeType;

- (instancetype)initWithFileURL:(NSURL *)fileURL
                           name:(NSString *)name {
    
    self = [super init];
    
    if (self) {
        _name = name;

        // extract filename from URL
        NSString *fileName = [fileURL lastPathComponent];
        
        _fileName = fileName;
        _mimeType = [AGFilePart getMimeTypeForName:fileName];
        _fileURL = fileURL;
    }
    
    return self;
}
            
// utility method to extract the mime type from a filename extension
+ (NSString *)getMimeTypeForName:(NSString *)filename {
    #ifdef __UTTYPE__
        NSString *extension = [filename stringByDeletingPathExtension];
    
        NSString *UTI = (__bridge_transfer NSString *) UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
        NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
        if (!contentType) {
            return @"application/octet-stream";
        } else {
            return contentType;
        }
    #else
        return @"application/octet-stream";
    #endif
}

@end

@implementation AGFileDataPart

@synthesize name =_name;
@synthesize fileName = _fileName;
@synthesize mimeType = _mimeType;

- (instancetype)initWithFileData:(NSData *)data
                            name:(NSString *)name
                        fileName:(NSString *)fileName
                        mimeType:(NSString *)mimeType {
    
    self = [super init];
    
    if (self) {
        _data = data;
        _name = name;
        _fileName = fileName;
        _mimeType = mimeType;
    }
    
    return self;
}

@end

@implementation AGStreamPart

@synthesize name =_name;
@synthesize fileName = _fileName;
@synthesize mimeType = _mimeType;

- (instancetype)initWithInputStream:(NSInputStream *)inputStream
                               name:(NSString *)name
                           fileName:(NSString *)fileName
                             length:(NSUInteger)length
                           mimeType:(NSString *)mimeType {
    
    self = [super init];
    
    if (self) {
        _inputStream = inputStream;
        _name = name;
        _fileName = fileName;
        _length = length;
        _mimeType = mimeType;
    }
    
    return self;    
}

@end