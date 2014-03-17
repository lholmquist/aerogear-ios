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
#import "AGCryptoConfig.h"

/**
 AGKeyManager manages different AGEncryptionService implementations. It is basically a
 factory that hides the concrete instantiations of a specific AGEncryptionService implementation.
 
 ## Example usage
 
 Here is an example usage of retrieving an encryption service (based on PBKDF2) and assigning to a data store to provide
 on-the fly encryption and decryption of data:
 
     // randomly generate salt
     NSData *salt = [AGRandomGenerator randomBytes];  // [1]
 
     // set up crypto params configuration object
     AGPassphraseCryptoConfig *config = [[AGPassphraseCryptoConfig alloc] init];  // [2]
     [config setSalt:salt];  // [3]
     [config setPassphrase:self.password.text];   // [4]
 
     // initialize the encryption service passing the config
     id<AGEncryptionService> encService = [[AGKeyManager manager] keyService:config];  // [5]
 
     // access Store Manager
     AGDataManager *manager = [AGDataManager manager];  // [6]
 
     // create store
     store = [manager store:^(id<AGStoreConfig> config) {
         [config setName:@"CredentialsStorage"];
         [config setType:@"ENCRYPTED_PLIST"];  // [7]
         [config setEncryptionService:encService];  // [8]
     }];
 
     // ok time to attempt reading..
     NSArray *data = [store readAll]) { // [9]
 
     if (data)
        // decryption succeeded!
 
 In [1] we initialize a random salt that will be used in the encryption. In [2] we initialize an instance of a
 CryptoConfig configuration object to set our crypto params. Here we use an PassphraseCryptoConfig object, that sets
 the necessary crypto params for the PBKDF2 Encryption Service, mainly the salt [3] and the passphrase [4].
 
 Now that we have setup the configuration, it’s time to obtain an instance of an EncryptionService and that’s exactly
 what we do in [5]. KeyManager parses the configuration and returns an instance of it. Because we passed an
 PassphraseCryptoConfig object, a PBKDF2 encryption service would be returned.
 
 In [6] we initialize our data store (an encrypted plist [7]), setting the encryption service we obtained earlier [8].
 Reading and saving operations are done like all the other stores, but this time the data are transparently
 encrypted/decrypted.
 
 In [9] we attempt to read data from the store. If that fails, then user supplied wrong crypto parameters
 (either passphrase or salt).
*/
@interface AGKeyManager : NSObject

/**
 * A factory method to instantiate the AGKeyManager object.
 *
 * @return the AGKeyManager object
 */
+ (instancetype)manager;

/**
 * Return an implementation of an AGEncryptionService based on the AGCryptoConfig configuration object passed in.
 * See AGPasswordKeyServices and AGPassphraseKeyServices for the different encyption providers.
 *
 * @param config The CryptoConfig object. See AGKeyStoreCryptoConfig and AGPassphraseCryptoConfig configuration objects.
 *
 * @return the newly created AGEncryptionService object.
 */
- (id<AGEncryptionService>)keyService:(id<AGCryptoConfig>)config;

/**
 * Removes am AGEncryptionService from the AGKeyManager object.
 *
 * @param name the name of the actual AGEncryptionService.
 *
 * @return the AGEncryptionService object.
 */
- (id<AGEncryptionService>)remove:(NSString*)name;

/**
 * Look up for an AGEncryptionService object.
 *
 * @param name the name of the actual AGEncryptionService.
 *
 * @return the AGEncryptionService object.
 */
- (id<AGEncryptionService>)keyServiceWithName:(NSString *)name;


@end
