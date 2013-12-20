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

/**
AGAuthzModule represents an OAuth2 module and provides an interface for managing OAuth2 dance. The
default implementation uses REST as the authz transport. Similar to the [Pipe](AGPipe), technical details of the
underlying system are not exposed.

## Login

Once you have a _valid_ user you can use that information to issue a login against the server, to start accessing
protected endpoints:

    AGAuthorizer* authorizer = [AGAuthorizer authorizer];

    _restAuthzModule = [authorizer authz:^(id<AGAuthzConfig> config) {
        config.name = @"restAuthMod";
        config.baseURL = [[NSURL alloc] initWithString:@"https://accounts.google.com"];
        config.authzEndpoint = @"/o/oauth2/auth";
        config.accessTokenEndpoint = @"/o/oauth2/token";
        config.clientId = @"XXXXXXX";
        config.clientSecret = @"XXXXXXX";
        config.redirectURL = @"org.aerogear.GoogleDrive:/oauth2Callback";
        config.scopes = @[@"https://www.googleapis.com/auth/drive"];
    }];

    [_restAuthzModule requestAccess:nil success:^(id object) {
       // object contain the access token needed to query exposed web service
       // You can use ipe as usual
    } failure:^(NSError *error) {
        // an error occurred
    }];
}

The ```requestAccess:success:failure:``` function deal with the OAuth dance. To manage callback to application,
the AeroGear uses URL scheme. Schema should be carefully defined in you plist application.

## Time out and Cancel pending operations

As with the case of Pipe, configured timeout interval (in the config object) and cancel operation in
_AGAuthenticationModule_ is supported too.
 */
@protocol AGAuthzModule <NSObject>


@property (nonatomic, readonly) NSString* type;
@property (nonatomic, readonly) NSString* baseURL;
@property (nonatomic, readonly) NSString* authzEndpoint;
@property (nonatomic, readonly) NSString* accessTokenEndpoint;
@property (nonatomic, readonly) NSString* redirectURL;
@property (nonatomic, readonly) NSArray* scopes;
@property (nonatomic, readonly) NSString* clientId;
@property (nonatomic, readonly) NSString* clientSecret;

-(void) requestAccess:(NSDictionary*) extraParameters
     success:(void (^)(id object))success
     failure:(void (^)(NSError *error))failure;

//TODO refreshAccess
//TODO revokeAccess
@end
