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
#import "AGHttpClient.h"
#import "AGHTTPMockHelper.h"

// access the timer of the operation for the purpose of testing
@interface AFHTTPRequestOperation (Testing)
@property (nonatomic, retain) NSTimer* timer;
@end

SPEC_BEGIN(AGHttpClientSpec)

    describe(@"AGHttpClient", ^{

        NSString * const PROJECTS = @"[{\"id\":1,\"title\":\"First Project\",\"style\":\"project-161-58-58\",\"tasks\":[]}, {\"id\":2,\"title\":\"Second Project\",\"style\":\"project-64-144-230\",\"tasks\":[]}]";

        __block BOOL finishedFlag;

        context(@"when newly created", ^{

            __block AGHttpClient* _restClient = nil;

            beforeEach(^{

                NSURL* baseURL = [NSURL URLWithString:@"http://server.com/context/"];

                _restClient = [AGHttpClient clientFor:baseURL];
                _restClient.parameterEncoding = AFJSONParameterEncoding;
            });

            afterEach(^{
                // remove all handlers installed by test methods
                // to avoid any interference
                [AGHTTPMockHelper clearAllMockedRequests];

                finishedFlag = NO;
            });

            it(@"should not be nil", ^{

                [_restClient shouldNotBeNil];
            });

            it(@"should successfully perform GET", ^{
                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];

                [_restClient getPath:@"projects" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    [responseObject shouldNotBeNil];

                    finishedFlag = YES;

                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    // nope
                } ];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });

        });

        context(@"timeout should be honoured", ^{

            NSInteger const TIMEOUT_ERROR_CODE = -1001;

            __block AGHttpClient* _restClient = nil;

            beforeEach(^{
                NSURL* baseURL = [NSURL URLWithString:@"http://server.com/context/"];

                // Note: we set the timeout(sec) to a low level so that
                // we can test the timeout methods with adjusting response delay
                _restClient = [AGHttpClient clientFor:baseURL timeout:1];
                _restClient.parameterEncoding = AFJSONParameterEncoding;
            });

            afterEach(^{
                // remove all handlers installed by test methods
                // to avoid any interference
                [AGHTTPMockHelper clearAllMockedRequests];

                finishedFlag = NO;
            });

            it(@"when performing PUT", ^{
                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]
                                        status:200
                                   requestTime:2]; // two secs delay

                NSMutableDictionary* project = [NSMutableDictionary
                        dictionaryWithObjectsAndKeys:@"0", @"id", @"First Project", @"title",
                                                     @"project-161-58-58", @"style", nil];

                [_restClient putPath:@"projects/0" parameters:project success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    // nope

                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    [[theValue(error.code) should] equal:theValue(TIMEOUT_ERROR_CODE)];
                    finishedFlag = YES;
                }];

                // NOTE:
                /// we set kiwi's shouldEventually to 5 secs > 2 secs of the simulated timeout
                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });

            it(@"when performing POST", ^{
                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]
                                        status:200
                                   requestTime:2]; // two secs delay

                NSMutableDictionary* project = [NSMutableDictionary
                        dictionaryWithObjectsAndKeys:@"First Project", @"title",
                                                     @"project-161-58-58", @"style", nil];

                [_restClient postPath:@"projects" parameters:project success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    // nope

                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    [[theValue(error.code) should] equal:theValue(TIMEOUT_ERROR_CODE)];
                    finishedFlag = YES;
                }];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });

            it(@"when performing successive POST's and the second one timeouts", ^{
                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];

                NSMutableDictionary* projectFirst = [NSMutableDictionary
                        dictionaryWithObjectsAndKeys:@"First Project", @"title",
                                                     @"project-161-58-58", @"style", nil];

                [_restClient postPath:@"projects" parameters:projectFirst success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    [responseObject shouldNotBeNil];

                    NSMutableDictionary* projectSecond = [NSMutableDictionary
                            dictionaryWithObjectsAndKeys:@"Second Project", @"title",
                                                         @"project-111-45-51", @"style", nil];

                    [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]
                                            status:200
                                       requestTime:2]; // two secs delay

                    [_restClient postPath:@"projects" parameters:projectSecond success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        // nope
                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        [[theValue(error.code) should] equal:theValue(TIMEOUT_ERROR_CODE)];
                        finishedFlag = YES;
                    } ];

                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    // nope
                }];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });

            it(@"when performing successive PUT's and the second one timeouts", ^{
                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];

                NSMutableDictionary* projectFirst = [NSMutableDictionary
                        dictionaryWithObjectsAndKeys:@"0", @"id", @"First Project", @"title",
                                                     @"project-161-58-58", @"style", nil];

                [_restClient putPath:@"projects/0" parameters:projectFirst success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    [responseObject shouldNotBeNil];

                    NSMutableDictionary* projectSecond = [NSMutableDictionary
                            dictionaryWithObjectsAndKeys:@"1", @"id", @"Second Project", @"title",
                                                         @"project-111-45-51", @"style", nil];

                    // install the mock:
                    [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]
                                            status:200
                                       requestTime:2]; // two secs delay

                    [_restClient putPath:@"projects/1" parameters:projectSecond success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        // nope

                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        [[theValue(error.code) should] equal:theValue(TIMEOUT_ERROR_CODE)];
                        finishedFlag = YES;
                    } ];

                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    // nope
                }];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });

            it(@"when performing POST then PUT and PUT timeouts", ^{
                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];

                NSMutableDictionary* projectFirst = [NSMutableDictionary
                        dictionaryWithObjectsAndKeys:@"First Project", @"title",
                                                     @"project-161-58-58", @"style", nil];

                [_restClient postPath:@"projects" parameters:projectFirst success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    [responseObject shouldNotBeNil];

                    NSMutableDictionary* projectSecond = [NSMutableDictionary
                            dictionaryWithObjectsAndKeys:@"1", @"id", @"Second Project", @"title",
                                                         @"project-111-45-51", @"style", nil];

                    // install the mock:
                    [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]
                                            status:200
                                       requestTime:2]; // two secs delay

                    [_restClient putPath:@"projects/1" parameters:projectSecond success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        // nope
                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        [[theValue(error.code) should] equal:theValue(TIMEOUT_ERROR_CODE)];
                        finishedFlag = YES;
                    } ];

                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    // nope
                }];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });

            it(@"when performing PUT then POST and POST timeouts", ^{

                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];

                NSMutableDictionary* projectFirst = [NSMutableDictionary
                        dictionaryWithObjectsAndKeys:@"0", @"id", @"First Project", @"title",
                                                     @"project-161-58-58", @"style", nil];

                [_restClient putPath:@"projects/0" parameters:projectFirst success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    [responseObject shouldNotBeNil];

                    NSMutableDictionary* projectSecond = [NSMutableDictionary
                            dictionaryWithObjectsAndKeys:@"Second Project", @"title",
                                                         @"project-111-45-51", @"style", nil];

                    // install the mock:
                    [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]
                                            status:200
                                       requestTime:2]; // two secs delay

                    [_restClient postPath:@"projects" parameters:projectSecond success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        // nope
                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        [[theValue(error.code) should] equal:theValue(TIMEOUT_ERROR_CODE)];
                        finishedFlag = YES;
                    } ];

                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    // nope
                }];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });
        });
    });

SPEC_END