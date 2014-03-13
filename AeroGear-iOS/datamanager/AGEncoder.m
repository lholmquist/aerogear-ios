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

#import "AGEncoder.h"
#import "AGEncryptionService.h"

@implementation AGPListEncoder {
    NSPropertyListFormat _format;
}

- (id) init {
    return [self initWithFormat:NSPropertyListXMLFormat_v1_0];
}

- (id) initWithFormat:(NSPropertyListFormat)format {
    if(self = [super init]) {
        _format = format;
    }
    return self;
}

- (NSData *)encode:(id)plist error:(NSError **)error {
    return [NSPropertyListSerialization dataWithPropertyList:plist format:_format
                                                     options:0 error:error];
}

- (id)decode:(NSData *)data error:(NSError **)error {   
    return [NSPropertyListSerialization propertyListWithData:data
                                                     options:0
                                                      format:&_format error:error];
}

- (BOOL)isValid:(id)plist {
    return [NSPropertyListSerialization propertyList:plist isValidForFormat:_format];
}

@end

@implementation AGEncryptedPListEncoder {
    id<AGEncryptionService> _encryptionService;

    AGPListEncoder *_encoder;
}

- (id) initWithEncryptionService:(id<AGEncryptionService>)encryptionService {
    if (self = [super init]) {
        _encryptionService = encryptionService;
        _encoder = [[AGPListEncoder alloc] initWithFormat:NSPropertyListBinaryFormat_v1_0];
    }

    return self;
}
- (NSData *)encode:(id)plist error:(NSError **)error {
    // convert to plist
    NSData *encodedData = [_encoder encode:plist error:error];

    return [_encryptionService encrypt:encodedData];
}

- (id)decode:(NSData *)data error:(NSError **)error {
    NSData *decryptedData = [_encryptionService decrypt:data];

    return [_encoder decode:decryptedData error:error];
}

- (BOOL)isValid:(id)plist {
    return [_encoder isValid:plist];
}

@end


@implementation AGJsonEncoder

- (NSData *)encode:(id)json error:(NSError **)error {
    return [NSJSONSerialization dataWithJSONObject:json
                                           options:NSJSONWritingPrettyPrinted
                                             error:error];
}

- (id)decode:(NSData *)data error:(NSError **)error {
    id arr = [NSJSONSerialization JSONObjectWithData:data
                                             options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves
                                               error:error];
    
    return arr;
}

- (BOOL)isValid:(id)json {
    return [NSJSONSerialization isValidJSONObject:json];
}

@end
