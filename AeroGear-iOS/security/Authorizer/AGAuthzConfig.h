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
#import "AGConfig.h"

/**
 * Represents the public API to configure AGAuthzModule objects.
 */
@protocol AGAuthzConfig <AGConfig>

/**
 * Applies the baseURL to the configuration.
 */
@property (strong, nonatomic) NSURL* baseURL;

/**
 * Applies the "authorization endpoint" to the request token.
 */
@property (copy, nonatomic) NSString* authzEndpoint;

/**
* Applies the "callback URL" once request token issued.
*/
@property (copy, nonatomic) NSString* redirectURL;

/**
 * Applies the "access token endpoint" to the exchange code for access token.
 */
@property (copy, nonatomic) NSString* accessTokenEndpoint;


/**
 * Applies the "scope" of the authorization.
 */
@property (copy, nonatomic) NSArray* scopes;

/**
 * Applies the "client id" obtained with the client registration process.
 */
@property (copy, nonatomic) NSString* clientId;

/**
 * Applies the "client secret" obtained with the client registration process.
 */
@property (copy, nonatomic) NSString* clientSecret;

/**
 * The timeout interval for a request to complete.
 */
@property (assign, nonatomic) NSTimeInterval timeout;

@end
