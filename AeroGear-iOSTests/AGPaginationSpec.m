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
#import "AGRESTPipe.h"
#import "AGHTTPMockHelper.h"
#import "AGNSMutableArray+Paging.h"

SPEC_BEGIN(AGPaginationSpec)

describe(@"AGPagination", ^{
    
    NSString * const RESPONSE_FIRST = @"[{\"id\":1,\"color\":\"black\",\"brand\":\"BMW\"}]";
    NSString * const RESPONSE_SECOND =  @"[{\"id\":2,\"color\":\"black\",\"brand\":\"FIAT\"}]";
    NSString * const RESPONSE_TWO_ITEMS = @"[{\"id\":1,\"color\":\"black\",\"brand\":\"BMW\"},{\"id\":2,\"color\":\"black\",\"brand\":\"FIAT\"}]";

    __block id<AGPipe> pipe = nil;
    __block BOOL finishedFlag;
    
    context(@"when newly created", ^{

        beforeEach(^{
            AGPipeConfiguration* config = [[AGPipeConfiguration alloc] init];
            [config setBaseURL:[NSURL URLWithString:@"http://server.com/context/"]];
            [config setName:@"cars"];

            [config setPageConfig:^(id<AGPageConfig> pageConfig) {
                [pageConfig setNextIdentifier:@"AG-Links-Next"];
                [pageConfig setPreviousIdentifier:@"AG-Links-Previous"];
                [pageConfig setMetadataLocation:@"header"];
            }];

            pipe = [AGRESTPipe pipeWithConfig:config];
        });

        afterEach(^{
            // remove all handlers installed by test methods
            // to avoid any interference
            [AGHTTPMockHelper clearAllMockedRequests];

            finishedFlag = NO;
        });

        it(@"should not be nil", ^{
            [(id)pipe shouldNotBeNil];
        });

        it(@"should move to the next page", ^{
            // set the mocked response for the first page
            [AGHTTPMockHelper mockResponse:[RESPONSE_FIRST dataUsingEncoding:NSUTF8StringEncoding]
                                   headers:@{@"AG-Links-Next" : @"http://server.com/context?color=black&offset=1&limit=1"}];

            __block NSMutableArray *pagedResultSet;

            [pipe readWithParams:@{@"color" : @"black", @"offset" : @"0", @"limit" : [NSNumber numberWithInt:1]} success:^(id responseObject) {
                pagedResultSet = responseObject;  // page 1

                // hold the "id" from the first page, so that
                // we can match with the result when we move
                // to the next page down in the test.
                NSString *car_id = [[[responseObject objectAtIndex:0] objectForKey:@"id"] stringValue];

                // set the mocked response for the second page
                [AGHTTPMockHelper mockResponse:[RESPONSE_SECOND dataUsingEncoding:NSUTF8StringEncoding]];

                // move to the next page
                [pagedResultSet next:^(id responseObject) {

                    NSString *id = [[[responseObject objectAtIndex:0] objectForKey:@"id"] stringValue];

                    [[car_id shouldNot] equal:id];
                    finishedFlag = YES;

                } failure:^(NSError *error) {
                    // nope
                }];
            } failure:^(NSError *error) {
                // nope
            }];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });

        it(@"should NOT move back from the first page", ^{
            // set the mocked response for the first page
            [AGHTTPMockHelper mockResponse:[RESPONSE_FIRST dataUsingEncoding:NSUTF8StringEncoding]
                                   headers:@{@"AG-Links-Next" : @"http://server.com/context?color=black&offset=1&limit=1"}];

            __block NSMutableArray *pagedResultSet;

            // fetch the first page
            [pipe readWithParams:@{@"color" : @"black", @"offset" : @"0", @"limit" : [NSNumber numberWithInt:1]} success:^(id responseObject) {
                pagedResultSet = responseObject;  // page 1

                // simulate "Bad Request" as in the case of AGController
                // when you try to move back from the first page
                [AGHTTPMockHelper mockResponseStatus:400];

                // move back to an invalid page
                [pagedResultSet previous:^(id responseObject) {
                    // nope
                } failure:^(NSError *error) {
                    finishedFlag = YES;

                    // Note: "failure block" was called here
                    // because we were at the first page and we
                    // requested to go previous, that is to a non
                    // existing page ("AG-Links-Previous" identifier
                    // was missing from the headers response and we
                    // got a 400 http error).
                    //
                    // Note that this is not always the case, cause some
                    // remote api's can send back either an empty list or
                    // list with results, instead of throwing an error(see GitHub integration testcase)
                }];
            } failure:^(NSError *error) {
                // nope
            }];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });

        it(@"should move to the next page and then back", ^{
            // set the mocked response for the first page
            [AGHTTPMockHelper mockResponse:[RESPONSE_FIRST dataUsingEncoding:NSUTF8StringEncoding]
                                   headers:@{@"AG-Links-Next" : @"http://server.com/context?color=black&offset=1&limit=1"}];

            __block NSMutableArray *pagedResultSet;

            // fetch the first page
            [pipe readWithParams:@{@"color" : @"black", @"offset" : @"0", @"limit" : [NSNumber numberWithInt:1]}
                    success:^(id responseObject) {
                        pagedResultSet = responseObject;  // page 1

                        // hold the "car id" from the first page, so that
                        // we can match with the result when we move
                        // to the next page down in the test.
                        NSString *car_id = [[[responseObject objectAtIndex:0] objectForKey:@"id"] stringValue];

                        [AGHTTPMockHelper mockResponse:[RESPONSE_SECOND dataUsingEncoding:NSUTF8StringEncoding]
                                               headers:
                                                       @{@"AG-Links-Next" : @"http://server.com/context?color=black&offset=2&limit=1",
                                                               @"AG-Links-Previous" : @"http://server.com/context?color=black&offset=0&limit=1"}];

                        // move to the second page
                        [pagedResultSet next:^(id responseObject) {

                            // set the mocked response for the first page again
                            [AGHTTPMockHelper mockResponse:[RESPONSE_FIRST dataUsingEncoding:NSUTF8StringEncoding]
                                                   headers:@{@"AG-Links-Next" : @"http://server.com/context?color=black&offset=1&limit=1"}];

                            // move backwards (aka. page 1)
                            [pagedResultSet previous:^(id responseObject) {

                                NSString *id = [[[responseObject objectAtIndex:0] objectForKey:@"id"] stringValue];

                                [[car_id should] equal:id];
                                finishedFlag = YES;

                            } failure:^(NSError *error) {
                                // nope
                            }];
                        } failure:^(NSError *error) {
                            // nope
                        }];
                    } failure:^(NSError *error) {
                        // nope
                    }];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });

        it(@"should honour the override of the parameter provider", ^{
            // the default parameter provider
            AGPipeConfiguration* config = [[AGPipeConfiguration alloc] init];
            [config setBaseURL:[NSURL URLWithString:@"http://server.com/context/"]];
            [config setName:@"cars"];
            [config setPageConfig:^(id<AGPageConfig> pageConfig) {
                [pageConfig setNextIdentifier:@"AG-Links-Next"];
                [pageConfig setPreviousIdentifier:@"AG-Links-Previous"];
                [pageConfig setParameterProvider:@{@"color" : @"black", @"offset" : @"0", @"limit" : [NSNumber numberWithInt:1]}];
                [pageConfig setMetadataLocation:@"header"];
            }];

            pipe = [AGRESTPipe pipeWithConfig:config];

            [AGHTTPMockHelper mockResponse:[RESPONSE_FIRST dataUsingEncoding:NSUTF8StringEncoding]
                                   headers:@{@"AG-Links-Next" : @"http://server.com/context?color=black&offset=1&limit=1"}];

            [pipe readWithParams:nil success:^(id responseObject) {

                [[responseObject should] haveCountOf:1];

                // set the mocked response for the first page
                [AGHTTPMockHelper mockResponse:[RESPONSE_TWO_ITEMS dataUsingEncoding:NSUTF8StringEncoding]];

                // override the results per page from parameter provider
                [pipe readWithParams:@{@"color" : @"black", @"offset" : @"0", @"limit" : [NSNumber numberWithInt:2]} success:^(id responseObject) {

                    [[responseObject should] haveCountOf:2];

                    finishedFlag = YES;
                } failure:^(NSError *error) {
                    // nope
                }];

            } failure:^(NSError *error) {
                // nope
            }];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });

        it(@"should fail to move to the next page if 'next identifier' is bogus", ^{
            AGPipeConfiguration* config = [[AGPipeConfiguration alloc] init];
            [config setBaseURL:[NSURL URLWithString:@"http://server.com/context/"]];
            [config setName:@"cars"];
            [config setPageConfig:^(id<AGPageConfig> pageConfig) {
                [pageConfig setMetadataLocation:@"header"];
                // wrong setting:
                [pageConfig setNextIdentifier:@"foo"];

            }];

            pipe = [AGRESTPipe pipeWithConfig:config];

            // set the mocked response for the first page
            [AGHTTPMockHelper mockResponse:[RESPONSE_FIRST dataUsingEncoding:NSUTF8StringEncoding]
                                   headers:
                                           @{@"AG-Links-Next" : @"http://server.com/context?color=black&offset=1&limit=1",
                                                   @"AG-Links-Previous" : @"http://server.com/context?color=black&offset=0&limit=1"}];

            __block NSMutableArray *pagedResultSet;

            [pipe readWithParams:@{@"color" : @"black", @"offset" : @"0", @"limit" : [NSNumber numberWithInt:1]} success:^(id responseObject) {

                pagedResultSet = responseObject;

                // simulate "Bad Request" as in the case of AGController
                // because the nextIdentifier is invalid ("foo" instead of "AG-Links-Next")
                [AGHTTPMockHelper mockResponseStatus:400];

                [pagedResultSet next:^(id responseObject) {
                    // nope
                } failure:^(NSError *error) {
                    // Note: failure is called cause the next identifier
                    // is invalid so we can't move to the next page
                    finishedFlag = YES;
                }];

            } failure:^(NSError *error) {
                // nope
            }];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });

        it(@"should fail to move to the previous page if 'previous identifier' is bogus", ^{
            AGPipeConfiguration* config = [[AGPipeConfiguration alloc] init];
            [config setBaseURL:[NSURL URLWithString:@"http://server.com/context/"]];
            [config setName:@"cars"];
            [config setPageConfig:^(id<AGPageConfig> pageConfig) {
                [pageConfig setMetadataLocation:@"header"];
                // wrong setting:
                [pageConfig setPreviousIdentifier:@"foo"];
            }];

            pipe = [AGRESTPipe pipeWithConfig:config];

            // set the mocked response for the first page
            [AGHTTPMockHelper mockResponse:[RESPONSE_FIRST dataUsingEncoding:NSUTF8StringEncoding]
                                   headers:
                                           @{@"AG-Links-Next" : @"http://server.com/context?color=black&offset=3&limit=1",
                                                   @"AG-Links-Previous" : @"http://server.com/context?color=black&offset=1&limit=1"}];

            __block NSMutableArray *pagedResultSet;

            [pipe readWithParams:@{@"color" : @"black", @"offset" : @"2", @"limit" : [NSNumber numberWithInt:1]} success:^(id responseObject) {

                pagedResultSet = responseObject;

                // simulate "Bad Request" as in the case of AGController
                // because the previousIdentifier is invalid ("foo" instead of "AG-Links-Previous")
                [AGHTTPMockHelper mockResponseStatus:400];

                [pagedResultSet next:^(id responseObject) {
                    // nope
                } failure:^(NSError *error) {
                    // Note: failure is called cause the previoys identifier
                    // is invalid so we can't move to the previous page
                    finishedFlag = YES;
                }];

            } failure:^(NSError *error) {
                // nope
            }];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });

        it(@"should fail to move to the previous page if 'previous identifier' is bogus", ^{
            AGPipeConfiguration* config = [[AGPipeConfiguration alloc] init];
            [config setBaseURL:[NSURL URLWithString:@"http://server.com/context/"]];
            [config setName:@"cars"];
            [config setPageConfig:^(id<AGPageConfig> pageConfig) {
                // wrong setting:
                [pageConfig setMetadataLocation:@"body"];
            }];

            pipe = [AGRESTPipe pipeWithConfig:config];

            __block NSMutableArray *pagedResultSet;

            // set the mocked response for the first page
            [AGHTTPMockHelper mockResponse:[RESPONSE_FIRST dataUsingEncoding:NSUTF8StringEncoding]
                                   headers:
                                           @{@"AG-Links-Next" : @"http://server.com/context?color=black&offset=3&limit=1",
                                                   @"AG-Links-Previous" : @"http://server.com/context?color=black&offset=1&limit=1"}];

            [pipe readWithParams:@{@"color" : @"black", @"offset" : @"2", @"limit" : [NSNumber numberWithInt:1]} success:^(id responseObject) {

                pagedResultSet = responseObject;

                // simulate "Bad Request" as in the case of AGController
                // because the metadata to extract next Identifiers
                // are located in the "headers" not in the "body"
                // as set in the config.
                [AGHTTPMockHelper mockResponseStatus:400];

                [pagedResultSet next:^(id responseObject) {
                    // nope
                } failure:^(NSError *error) {
                    finishedFlag = YES;
                }];

            } failure:^(NSError *error) {
                // nope
            }];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });
    });
});

SPEC_END