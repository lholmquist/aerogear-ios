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
                                                     options:NSPropertyListMutableContainersAndLeaves
                                                      format:&_format error:error];
}

- (BOOL)isValid:(id)plist {
    return [NSPropertyListSerialization propertyList:plist isValidForFormat:NSPropertyListXMLFormat_v1_0];
}

@end

@implementation AGEncryptedPListEncoder {
    id<AGEncryptionService> _encryptionService;
   
}

- (id) initWithEncryptionService:(id<AGEncryptionService>)encryptionService {
    if (self = [super init]) {
        _encryptionService = encryptionService;
    }
    return self;
}
- (NSData *)encode:(id)plist error:(NSError **)error {
    // convert to plist
    NSData *encodedData = [NSPropertyListSerialization dataWithPropertyList:plist
                                                                     format:NSPropertyListBinaryFormat_v1_0
                                                                    options:0 error:error];
    
    // encrypt it
    NSData *encryptedData = [_encryptionService encrypt:encodedData];
    return encryptedData;
}

- (id)decode:(NSData *)data error:(NSError **)error {
    NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
    
    NSData *decryptedData = [_encryptionService decrypt:data];
    
    id plainData =  [NSPropertyListSerialization propertyListWithData:decryptedData
                                                              options:NSPropertyListMutableContainersAndLeaves
                                                               format:&format error:error];
    
    return plainData;
}

- (BOOL)isValid:(id)plist {
    return [NSPropertyListSerialization propertyList:plist isValidForFormat:NSPropertyListBinaryFormat_v1_0];
}
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
