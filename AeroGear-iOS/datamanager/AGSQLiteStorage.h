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
#import "AGStore.h"
#import "AGStoreConfiguration.h"
#import "FMDatabase.h"
#import "AGEncoder.h"

@class AGSQLiteCommand;

/**
 An AGStore implementation that uses a SQLite for storage. The storage is a key value store. The content is serialized
 in JSON output.
 
 *NOTE:*
 You must adhere to the rules governing the serialization of data types for each respective field type.
 
 *IMPORTANT:* Users are not required to instantiate this class directly, instead an instance of this class is returned
 automatically when an DataStore with the _type_ config option is set to _"SQLITE"_. See AGDataManager and AGStore class
 documentation for more information.
 
 ## Create a DataManager with a SQLite store backend
 
 Below is a small example on how to use SQLite:
 
    // initialize SQLite store (if the file does not exist it will be created)
    AGDataManager* manager = [AGDataManager manager];
    id<AGStore> store = [manager store:^(id<AGStoreConfig> config) {
      [config setName:@"secrets"]; // will be used as the filename for the sqlite database.
      [config setType:@"SQLITE"];  // specify you want to use SQLite store.
    }];
 
    // the object to save (e.g. a dictionary)
    NSDictionary *otp = [NSDictionary dictionaryWithObjectsAndKeys:@"19a01df0281afcdbe", @"otp", @"1", @"id", nil];
 
    // save it
    NSError *error;
 
    if (![store save:otp error:&error])
    NSLog(@"Save: An error occurred during save! \n%@", error);
 
 
 The ```read```, ```reset``` or ```remove``` methods found in AGStore behave the same, as on the default
 ("in memory") store.
 
 */
@interface AGSQLiteStorage : NSObject <AGStore> {
@protected
    FMDatabase *_database;
    NSString* _recordId;
    NSString* _databaseName;
    NSString* _path;
    id<AGEncoder> _encoder;
    NSString* _type;
    AGSQLiteCommand * _command;
}

+(instancetype) storeWithConfig:(id<AGStoreConfig>) storeConfig;
-(instancetype) initWithConfig:(id<AGStoreConfig>) storeConfig;
@end
