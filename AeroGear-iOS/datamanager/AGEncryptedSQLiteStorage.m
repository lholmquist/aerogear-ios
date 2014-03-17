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

#import "AGEncryptedSQLiteStorage.h"
#import "AGSQLiteCommand.h"
#import "AGBaseStorage.h"

@implementation AGEncryptedSQLiteStorage

// ==============================================
// ======== 'factory' and 'init' section ========
// ==============================================

-(instancetype) initWithConfig:(id<AGStoreConfig>) storeConfig {
    self = [super init];
    if (self) {
        _type = @"ENCRYPTED_SQLITE";

        AGStoreConfiguration* config = (AGStoreConfiguration*) storeConfig;
        _recordId = config.recordId;
        _databaseName = config.name;
        NSURL *file = [AGBaseStorage storeURLWithName:[_databaseName stringByAppendingString:@"%@.sqlite3"]];
        _database = [FMDatabase databaseWithPath:[file path]];
        _encoder = [[AGEncryptedPListEncoder alloc] initWithEncryptionService:storeConfig.encryptionService];
        _command = [[AGSQLiteCommand alloc] initWithDatabase:_database name:_databaseName recordId:_recordId encoder:_encoder];
    }
    return self;
}
@end
