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
#import "AGAuthzModule.h"
#import "AGAuthzConfig.h"

/**
  AGAuthorizer manages different AGAuthzModule implementations. It is basically a
  factory that hides the concrete instantiation of a specific AGAuthzModule implementation.
  The class offers simple APIs to add, remove, or get access to a 'authorization module'.
 
## Creating an Authorizer with an Authorizer module

Below is an example that creates an Authorizer for OAuth2 implementation.

    AGAuthorizer* authorizer = [AGAuthorizer authorizer];

    _restAuthzModule = [authorizer authz:^(id<AGAuthzConfig> config) {
        config.name = @"restAuthMod";
        config.baseURL = [[NSURL alloc] initWithString:@"https://accounts.google.com"];
        config.authzEndpoint = @"/o/oauth2/auth";
        config.accessTokenEndpoint = @"/o/oauth2/token";
        config.clientId = @"XXXXX";
        config.redirectURL = @"org.aerogear.GoogleDrive:/oauth2Callback";
        config.scopes = @[@"https://www.googleapis.com/auth/drive"];
    }];;
 */
@interface AGAuthorizer : NSObject

/**
 * A factory method to instantiate an empty AGAuthorizer.
 *
 * @return the AGAuthenticator object
 */
+(instancetype) authorizer;

/**
 * Adds a new AGAuthzModule object, based on the given configuration object.
 *
 * @param config A block object which passes in an implementation of the AGAuthzConfig protocol.
 * the object is used to configure the AGAuthzModule object.
 *
 * @return the newly created AGAuthzModule object
 */
-(id<AGAuthzModule>) authz:(void (^)(id<AGAuthzConfig> config)) config;

/**
 * Removes a AGAuthzModule implementation from the AGAuthorizer. The authz module,
 * to be removed is determined by the moduleName argument.
 *
 * @param moduleName The name of the actual auth module object.
 */
-(id<AGAuthzModule>)remove:(NSString*) moduleName;

/**
 * Loads a given AGAuthzModule implementation, based on the given moduleName argument.
 *
 * @param moduleName The name of the actual authz module object.
 */
-(id<AGAuthzModule>)authzModuleWithName:(NSString*) moduleName;


@end
