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

#import <Kiwi/Kiwi.h>
#import "AGHTTPMockHelper.h"
#import "AGHttpClient.h"
#import "AGAuthzConfiguration.h"
#import "AGRestAuthzModule.h"

// useful macro to check iOS version
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

SPEC_BEGIN(AGRestAuthzModuleSpec)

describe(@"AGRestAuthzModule", ^{
    context(@"when newly created", ^{

        __block NSString *ACCESS_TOKEN_RESPONSE = nil;

        __block AGRestAuthzModule* restAuthzModule = nil;

        __block BOOL finishedFlag;
        
        //NSInteger const TIMEOUT_ERROR_CODE = SYSTEM_VERSION_LESS_THAN(@"6")? -999: -1001;

        beforeAll(^{
            ACCESS_TOKEN_RESPONSE =  @"eee";
        });

        beforeEach(^{
            //NSURL* baseURL = [NSURL URLWithString:@"https://server.com/context/"];

            // setup REST Authenticator
            AGAuthzConfiguration* config = [[AGAuthzConfiguration alloc] init];
            config.name = @"restAuthMod";
            config.baseURL = [[NSURL alloc] initWithString:@"https://accounts.google.com"];
            config.authzEndpoint = @"/o/oauth2/auth";
            config.accessTokenEndpoint = @"/o/oauth2/token";
            config.clientId = @"XXXXX";
            config.redirectURL = @"org.aerogear.GoogleDrive:/oauth2Callback";
            config.scopes = @[@"https://www.googleapis.com/auth/drive"];
            config.timeout = 1; // this is just for testing of timeout methods

            restAuthzModule = [AGRestAuthzModule moduleWithConfig:config];
        });

        afterEach(^{
            // remove all handlers installed by test methods
            // to avoid any interference
            [AGHTTPMockHelper clearAllMockedRequests];

            finishedFlag = NO;
        });

        it(@"should not be nil", ^{
            [restAuthzModule shouldNotBeNil];
        });

        // TODO AGIOS-144


    });
});

SPEC_END