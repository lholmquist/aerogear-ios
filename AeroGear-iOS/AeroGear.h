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

#ifndef _AEROGEAR_
#define _AEROGEAR_

#pragma mark - base
#import "AGConfig.h"

#pragma mark - Pipeline
#import "AGPipe.h"
#import "AGPipeline.h"
#import "AGPipeConfig.h"
#import "AGNSMutableArray+Paging.h"
#import "AGMultipart.h"

#pragma mark - DataManager
#import "AGStore.h"
#import "AGDataManager.h"
#import "AGStoreConfig.h"

#pragma mark - Security

#pragma mark - Authentication
#import "AGAuthenticationModule.h"
#import "AGAuthenticator.h"
#import "AGAuthConfig.h"

#pragma mark - Authorization
#import "AGAuthzModule.h"
#import "AGAuthorizer.h"
#import "AGAuthzConfig.h"

#pragma mark - Encryption
#import "AGCryptoConfig.h"
#import "AGKeyStoreCryptoConfig.h"
#import "AGPassphraseCryptoConfig.h"
#import "AGKeyManager.h"
#import "AGEncryptionService.h"

#endif /* _AEROGEAR_ */

