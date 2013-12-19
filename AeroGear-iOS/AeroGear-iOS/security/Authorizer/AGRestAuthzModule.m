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

#import "AGRestAuthzModule.h"
#import "AGAuthzConfiguration.h"
#import "AFHTTPClient.h"


@implementation AGRestAuthzModule {
    // ivars
    AFHTTPClient* _restClient;
}

// =====================================================
// ======== public API (AGAuthenticationModule) ========
// =====================================================
@synthesize type = _type;
@synthesize baseURL = _baseURL;
@synthesize authzEndpoint = _authzEndpoint;
@synthesize redirectURL = _redirectURL;
@synthesize clientId = _clientId;
@synthesize clientSecret = _clientSecret;
@synthesize scopes = _scopes;

// custom getters for our properties (from AGAuthenticationModule)
-(NSString*) authEndpoint {
    return [_baseURL stringByAppendingString:_authzEndpoint];
}

// ==============================================================
// ======== internal API (AGAuthenticationModuleAdapter) ========
// ==============================================================
@synthesize accessTokens = _accessTokens;



// ==============================================
// ======== 'factory' and 'init' section ========
// ==============================================

+(id) moduleWithConfig:(id<AGAuthzConfig>) authzConfig {
    return [[self alloc] initWithConfig:authzConfig];
}

-(id) initWithConfig:(id<AGAuthzConfig>) authzConfig {
    self = [super init];
    if (self) {
        // set all the things:
        AGAuthzConfiguration* config = (AGAuthzConfiguration*) authzConfig;
        _baseURL = config.baseURL.absoluteString;
        _type = config.type;
        _authzEndpoint = config.authzEndpoint;
        _redirectURL = config.redirectURL;
        _clientId = config.clientId;
        _clientSecret = config.clientSecret;
        
        _restClient = [AGHttpClient clientFor:config.baseURL timeout:config.timeout];
        _restClient.parameterEncoding = AFJSONParameterEncoding;
    }

    return self;
}

-(void)dealloc {
    _restClient = nil;
}


// =====================================================
// ======== public API (AGAuthenticationModule) ========
// =====================================================
-(void) requestAccess:(NSDictionary*) extraParameters
              success:(void (^)(id object))success
              failure:(void (^)(NSError *error))failure {

    // Form the URL string.
    NSString *targetURLString = [NSString stringWithFormat:@"%@%@?scope=%@&redirect_uri=%@&client_id=%@&response_type=code",
                    self.baseURL,
                    self.authzEndpoint,
                    [self scope],
                    _redirectURL,
                    _clientId];
    //TODO add extraParam
    NSMutableDictionary *authzParameters = [[NSMutableDictionary alloc] initWithDictionary:extraParameters];
    [_restClient postPath:targetURLString parameters:extraParameters success:^(AFHTTPRequestOperation *operation, id responseObject) {


        if (success) {
            NSLog(@"Invoking successblock....");
            success(responseObject);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        if (failure) {
            NSLog(@"Invoking failure block....");
            failure(error);
        }
    }];
}

// private method
-(void) readAndStashToken:(AFHTTPRequestOperation*) operation {
    _accessTokens = [[NSMutableDictionary alloc] init];
}

// ==============================================================
// ======== internal API (AGAuthenticationModuleAdapter) ========
// ==============================================================

- (NSString*) scope {
    // Create a string to concatenate all scopes existing in the _scopes array.
    NSString *scope = @"";
    for (int i=0; i<[_scopes count]; i++) {
        scope = [scope stringByAppendingString:[self urlEncodeString:[_scopes objectAtIndex:i]]];

        // If the current scope is other than the last one, then add the "+" sign to the string to separate the scopes.
        if (i < [_scopes count] - 1) {
            scope = [scope stringByAppendingString:@"+"];
        }
    }
    return scope;
}

-(NSString *)urlEncodeString:(NSString *)stringToURLEncode{
    // URL-encode the parameter string and return it.
    CFStringRef encodedURL = CFURLCreateStringByAddingPercentEscapes(NULL,
            (__bridge CFStringRef) stringToURLEncode,
            NULL,
            (__bridge CFStringRef)@"!@#$%&*'();:=+,/?[]",
            kCFStringEncodingUTF8);
    return (NSString *)CFBridgingRelease(encodedURL);
}


- (BOOL)isAuthorized {
    return (nil != _accessTokens);
}

- (void)deauthorize {
    _accessTokens = nil;
}

@end
