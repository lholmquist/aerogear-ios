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

#import <UIKit/UIKit.h>
#import "AGRestAuthzModule.h"
#import "AGAuthzConfiguration.h"
#import "AGHttpClient.h"

NSString * const AGAppLaunchedWithURLNotification = @"AGAppLaunchedWithURLNotification";

@implementation AGRestAuthzModule {
    // ivars
    AGHttpClient* _restClient;
    id _applicationLaunchNotificationObserver;
}

// =====================================================
// ======== public API (AGAuthenticationModule) ========
// =====================================================
@synthesize type = _type;
@synthesize baseURL = _baseURL;
@synthesize authzEndpoint = _authzEndpoint;
@synthesize accessTokenEndpoint = _accessTokenEndpoint;
@synthesize redirectURL = _redirectURL;
@synthesize clientId = _clientId;
@synthesize clientSecret = _clientSecret;
@synthesize scopes = _scopes;

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
        _accessTokenEndpoint = config.accessTokenEndpoint;
        _redirectURL = config.redirectURL;
        _clientId = config.clientId;
        _clientSecret = config.clientSecret;
        _scopes = config.scopes;

        _restClient = [[AFHTTPClient alloc] initWithBaseURL:config.baseURL];
        _restClient.parameterEncoding = AFJSONParameterEncoding;

        _accessTokens = [NSMutableDictionary dictionary];
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
                                                           [self urlEncodeString:_redirectURL],
                                                           _clientId];
    NSURLRequest *request = [_restClient requestWithMethod:@"POST" path:targetURLString parameters:nil];
    _applicationLaunchNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AGAppLaunchedWithURLNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
        NSURL *url = [[notification userInfo] valueForKey:@"UIApplicationLaunchOptionsURLKey"];
        NSString* code = [[self parametersFromQueryString:[url query]] valueForKey:@"code"];
        [self exchangeAuthorizationCodeForAccessToken:code success:success failure:failure];
    }];


    [[UIApplication sharedApplication] openURL:[request URL]];
}


// ==============================================================
// ======== internal API (AGAuthenticationModuleAdapter) ========
// ==============================================================

-(void)exchangeAuthorizationCodeForAccessToken:(NSString*)code
                                       success:(void (^)(id object))success
                                       failure:(void (^)(NSError *error))failure {
    NSMutableDictionary* paramDict = [[NSMutableDictionary alloc] initWithDictionary:@{@"code":code, @"client_id":_clientId, @"redirect_uri": _redirectURL, @"grant_type":@"authorization_code"}];
    if (_clientSecret) {
        [paramDict setObject:_clientSecret forKey:@"client_secret"];
    }
    _restClient.parameterEncoding = AFFormURLParameterEncoding;
    [_restClient postPath:[NSString stringWithFormat:@"%@/%@", self.baseURL, self.accessTokenEndpoint] parameters:paramDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString* responseJSON = [[NSString alloc] initWithData:(NSData *)responseObject encoding:NSUTF8StringEncoding];
        if ([responseJSON rangeOfString:@"access_token"].location != NSNotFound) {
            NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData: responseObject
                                                                 options: NSJSONReadingMutableContainers
                                                                   error: nil];
            NSString* accessTokens = [JSON valueForKey:@"access_token"];
            if (success) {
                success(accessTokens);
            }
        }
        //TODO deal with refresh case
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(failure) {
            failure(nil);
        }
    }];

}


-(NSDictionary *) parametersFromQueryString:(NSString *)queryString {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (queryString) {
        NSScanner *parameterScanner = [[NSScanner alloc] initWithString:queryString];
        NSString *name = nil;
        NSString *value = nil;

        while (![parameterScanner isAtEnd]) {
            name = nil;
            [parameterScanner scanUpToString:@"=" intoString:&name];
            [parameterScanner scanString:@"=" intoString:NULL];

            value = nil;
            [parameterScanner scanUpToString:@"&" intoString:&value];
            [parameterScanner scanString:@"&" intoString:NULL];

            if (name && value) {
                parameters[[name stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            }
        }
    }

    return parameters;
}

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
