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
 An AGStore implementation that uses a [Property List](http://tinyurl.com/ccbo327) for storage. It can either use a
 PLIST or JSON serialization output format depending on type name passed when constructing the Store. If the type is
 'JSON' the store will use NSJSONSerialization  as its backend otherwise it will fell to use NSPropertyListSerialization.

 *NOTE:*
 You must adhere to the rules governing the serialization of data types for each respective plist type.
 
 *IMPORTANT:* Users are not required to instantiate this class directly, instead an instance of this class is returned
 automatically when an DataStore with the _type_ config option is set to _"PLIST"_ or _"JSON"_. See AGDataManager and
 AGStore class documentation for more information.

 ## Create a DataManager with a Property List store backend
 
 Below is a small example on how to save to the file system:

    // initialize plist store (if the file does not exist it will be created)
    AGDataManager* manager = [AGDataManager manager];
    id<AGStore> plistStore = [manager store:^(id<AGStoreConfig> config) {
        [config setName:@"secrets"]; // will be used as the filename for the plist
        // specify that a Property List is required and will use the PLIST format as its output
        [config setType:@"PLIST"];  // you can also use 'JSON' to instruct JSON serialization.
    }];
 
    // the object to save (e.g. a dictionary)
    NSDictionary *otp = [NSDictionary dictionaryWithObjectsAndKeys:@"19a01df0281afcdbe", @"otp", @"1", @"id", nil];

    // save it
    NSError *error;
        
    if (![plistStore save:otp error:&error])
        NSLog(@"Save: An error occurred during save! \n%@", error);

    
 The ```read```, ```reset``` or ```remove``` methods found in AGStore behave the same, as on the default
 ("in memory") store.
*/
@interface AGPropertyListStorage : AGBaseStorage <AGStore>

+ (instancetype)storeWithConfig:(id<AGStoreConfig>)storeConfig;
- (instancetype)initWithConfig:(id<AGStoreConfig>)storeConfig;

@end
