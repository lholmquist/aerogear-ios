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
#import "AGSQLiteStorage.h"
/**
 An AGStore implementation that uses a SQLite for storage and encryption. This storage is a variant of AGSQLiteStorage
 with encryption. You can use your encrypted store transparently, the same way you work with AGSQLiteStorage.

 *NOTE:*
 You must adhere to the rules governing the serialization of data types for each respective field type.

 *IMPORTANT:* Users are not required to instantiate this class directly, instead an instance of this class is returned
 automatically when an DataStore with the _type_ config option is set to _"ENCRYPTED_SQLITE"_.
 See AGDataManager and AGStore class documentation for more information.

 ## Create a DataManager with an encrypted SQLite store backend

 Below is a small example on how to use EncryptedSQLite:

    // randomly generate salt
    NSData *salt = [AGRandomGenerator randomBytes];  // [1]

    // set up crypto params configuration object
    AGPassphraseCryptoConfig *config = [[AGPassphraseCryptoConfig alloc] init];  // [2]
    [config setSalt:salt];  // 3
    [config setPassphrase:self.password.text];   // 4

    // initialize the encryption service passing the config
    id<AGEncryptionService> encService = [[AGKeyManager manager] keyService:config];  // [5]

    // access Store
    AGDataManager* manager = [AGDataManager manager];
    id<AGStore> store = [manager store:^(id<AGStoreConfig> config) {
      [config setName:@"secrets"]; // will be used as the filename for the sqlite database.
      [config setType:@"ENCRYPTED_SQLITE"];  // specify you want to use Encrypted SQLite store.
      [config setEncryptionService:encService]; // specify the encryption service
    }];


 The ```read```, ```reset``` or ```remove``` methods found in AGStore behave the same, as on the default ("in memory") store.

 */

@interface AGEncryptedSQLiteStorage : AGSQLiteStorage
@end
