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

#import "AGBaseStorage.h"

// error domain for stores
NSString * const AGStoreErrorDomain = @"AGStoreErrorDomain";

@implementation AGBaseStorage

+ (NSURL *)storeURLWithName:(NSString *)filename {
    if (!filename)
        return nil;

    // access 'Application Support' directory
    NSURL *supportURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                               inDomain:NSUserDomainMask appropriateForURL:nil
                                                                 create:YES error:nil];
    // append the filename
    return [supportURL URLByAppendingPathComponent:filename];
}

+ (NSString *)getOrSetIdForData:(NSMutableDictionary *)data withIdentifier:(NSString *)identifier {
    id recordId = data[identifier];
    
    // if the object hasn't set a recordId property
    if (!recordId) {
        //generate a UUID to be used instead
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        NSString *uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
        CFRelease(uuid);
        
        recordId = uuidStr;
        // set the generated ID for the newly object
        [data setValue:recordId forKey:identifier];
    }
    
    return recordId;
}

@end
