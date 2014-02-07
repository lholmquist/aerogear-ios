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
#import "AGRestAuthentication.h"
#import "AGAuthConfiguration.h"

SPEC_BEGIN(AGRestAuthenticationSpec)

describe(@"AGRestAuthentication", ^{
    
     NSString * const PASSING_USERNAME = @"john";
     NSString * const FAILING_USERNAME = @"fail";
     NSString * const LOGIN_PASSWORD = @"passwd";
     NSString * const ENROLL_PASSWORD = @"passwd";
     NSString * const LOGIN_SUCCESS_RESPONSE = @"{\"username\":\"%@\",\"roles\":[\"admin\"]}";

    __block BOOL finishedFlag;
    
    context(@"when newly created", ^{

        __block AGRestAuthentication* restAuthModule = nil;
        
        beforeEach(^{
            NSURL* baseURL = [NSURL URLWithString:@"https://server.com/context/"];

            // setup REST Authenticator
            AGAuthConfiguration* config = [[AGAuthConfiguration alloc] init];
            [config setBaseURL:baseURL];
            [config setEnrollEndpoint:@"auth/register"];

            restAuthModule = [AGRestAuthentication moduleWithConfig:config];
        });

        afterEach(^{
            // remove all handlers installed by test methods
            // to avoid any interference
            [AGHTTPMockHelper clearAllMockedRequests];

            finishedFlag = NO;
        });

        it(@"should not be nil", ^{
            [restAuthModule shouldNotBeNil];
        });

        it(@"should successfully login", ^{
            // install the mock:
            [AGHTTPMockHelper mockResponse:[[NSString stringWithFormat:LOGIN_SUCCESS_RESPONSE, PASSING_USERNAME]
                    dataUsingEncoding:NSUTF8StringEncoding]];

            [restAuthModule login:@{@"loginName": PASSING_USERNAME, @"password": LOGIN_PASSWORD} success:^(id responseObject) {
                [[[responseObject valueForKey:@"username"] should] equal:PASSING_USERNAME];
                finishedFlag = YES;
            } failure:^(NSError *error) {
                // nope
            }];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });

        it(@"should fail to login with wrong credentials", ^{
            [AGHTTPMockHelper mockResponseStatus:401];

            [restAuthModule login:@{@"loginName": FAILING_USERNAME, @"password": LOGIN_PASSWORD} success:^(id responseObject) {
                // nope
            } failure:^(NSError *error) {
               finishedFlag = YES;
            }];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });

        it(@"should successfully logout", ^{
            // install the mock:
            [AGHTTPMockHelper mockResponse:[[NSString stringWithFormat:LOGIN_SUCCESS_RESPONSE, PASSING_USERNAME]
                    dataUsingEncoding:NSUTF8StringEncoding]];

            [restAuthModule login:@{@"loginName": PASSING_USERNAME, @"password": LOGIN_PASSWORD} success:^(id object) {
                [restAuthModule logout:^{
                    finishedFlag = YES;

                } failure:^(NSError *error) {
                    // nope
                }];
            } failure:^(NSError *error) {
                // nope
            }];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });

        it(@"should successfully enroll", ^{
            // install the mock:
            [AGHTTPMockHelper mockResponse:[[NSString stringWithFormat:LOGIN_SUCCESS_RESPONSE, PASSING_USERNAME]
                    dataUsingEncoding:NSUTF8StringEncoding]];

            NSMutableDictionary* registerPayload = [NSMutableDictionary dictionary];

            [registerPayload setValue:@"John" forKey:@"firstname"];
            [registerPayload setValue:@"Doe" forKey:@"lastname"];
            [registerPayload setValue:@"emaadsil@mssssse.com" forKey:@"email"];
            [registerPayload setValue:PASSING_USERNAME forKey:@"username"];
            [registerPayload setValue:ENROLL_PASSWORD forKey:@"password"];
            [registerPayload setValue:@"admin" forKey:@"role"];

            [restAuthModule enroll:registerPayload success:^(id responseObject) {
                [[[responseObject valueForKey:@"username"] should] equal:PASSING_USERNAME];

                finishedFlag = YES;
            } failure:^(NSError *error) {
                // nope
            }];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });
    });
    
    context(@"timout should be honoured", ^{
        
        NSInteger const TIMEOUT_ERROR_CODE = -1001;
        
        __block AGRestAuthentication* restAuthModule = nil;
        
        beforeEach(^{
            NSURL* baseURL = [NSURL URLWithString:@"https://server.com/context/"];
            
            // setup REST Authenticator
            AGAuthConfiguration* config = [[AGAuthConfiguration alloc] init];
            [config setBaseURL:baseURL];
            [config setEnrollEndpoint:@"auth/register"];
            [config setTimeout:1]; // this is just for testing of timeout methods
            
            restAuthModule = [AGRestAuthentication moduleWithConfig:config];
        });
        
        afterEach(^{
            // remove all handlers installed by test methods
            // to avoid any interference
            [AGHTTPMockHelper clearAllMockedRequests];
            
            finishedFlag = NO;
        });

        it(@"on login", ^{
            // simulate delay in response
            // Note that pipe has been default configured for a timeout in 1 sec
            // here we simulate a delay of 2 sec
            
            // install the mock:
            [AGHTTPMockHelper mockResponse:[[NSString stringWithFormat:LOGIN_SUCCESS_RESPONSE, PASSING_USERNAME]
                    dataUsingEncoding:NSUTF8StringEncoding]
                                    status:200
                               requestTime:2]; // two secs delay
            
            [restAuthModule login:@{@"loginName": PASSING_USERNAME, @"password": LOGIN_PASSWORD} success:^(id responseObject) {
                // nope
            } failure:^(NSError *error) {
                [[theValue(error.code) should] equal:theValue(TIMEOUT_ERROR_CODE)];
                finishedFlag = YES;
            }];
            
            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });
        
        it(@"on logout", ^{
            // install the mock:
            [AGHTTPMockHelper mockResponse:[[NSString stringWithFormat:LOGIN_SUCCESS_RESPONSE, PASSING_USERNAME]
                                            dataUsingEncoding:NSUTF8StringEncoding]];
            
            [restAuthModule login:@{@"loginName": PASSING_USERNAME, @"password": LOGIN_PASSWORD} success:^(id object) {
                
                // install the mock:
                [AGHTTPMockHelper mockResponse:[[NSString stringWithFormat:LOGIN_SUCCESS_RESPONSE, PASSING_USERNAME]
                        dataUsingEncoding:NSUTF8StringEncoding]
                                        status:200
                                   requestTime:2]; // two secs delay
                
                [restAuthModule logout:^{
                    // nope
                    
                } failure:^(NSError *error) {
                    [[theValue(error.code) should] equal:theValue(TIMEOUT_ERROR_CODE)];
                    finishedFlag = YES;
                }];
            } failure:^(NSError *error) {
                // nope
            }];
            
            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });
        
        it(@"on enroll", ^{
            // simulate delay in response
            // Note that pipe has been default configured for a timeout in 1 sec
            // here we simulate a delay of 2 sec
            
            // install the mock:
            [AGHTTPMockHelper mockResponse:[[NSString stringWithFormat:LOGIN_SUCCESS_RESPONSE, PASSING_USERNAME]
                    dataUsingEncoding:NSUTF8StringEncoding]
                                    status:200
                               requestTime:2]; // two secs delay
            
            NSMutableDictionary* registerPayload = [NSMutableDictionary dictionary];
            
            [registerPayload setValue:@"John" forKey:@"firstname"];
            [registerPayload setValue:@"Doe" forKey:@"lastname"];
            [registerPayload setValue:@"emaadsil@mssssse.com" forKey:@"email"];
            [registerPayload setValue:PASSING_USERNAME forKey:@"username"];
            [registerPayload setValue:ENROLL_PASSWORD forKey:@"password"];
            [registerPayload setValue:@"admin" forKey:@"role"];
            
            
            [restAuthModule enroll:registerPayload success:^(id responseObject) {
                // nope
            } failure:^(NSError *error) {
                [[theValue(error.code) should] equal:theValue(TIMEOUT_ERROR_CODE)];
                
                finishedFlag = YES;
            }];
            
            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });
    });
});

SPEC_END