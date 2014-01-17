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

#import "AGPageWebLinkingExtractor.h"

SPEC_BEGIN(AGPageWebLinkingExtractorSpec)

describe(@"AGPageHeaderExtractor", ^{
    context(@"when newly created", ^{

        __block NSString *NEXT_PAGE_IDENTIFIER = nil;
        __block NSString *PREVIOUS_PAGE_IDENTIFIER = nil;

        __block NSDictionary *headers = nil;
        __block NSArray      *response = nil;

        __block AGPageWebLinkingExtractor *extractor = nil;

        beforeAll(^{
            // default names for paging
            NEXT_PAGE_IDENTIFIER = @"next";
            PREVIOUS_PAGE_IDENTIFIER = @"previous";

            // mock up paging response headers (extracted from AGController)
            headers = @{
                    @"Link" : @"<http://controllerdemo-danbev.rhcloud.com/aerogear-controller-demo/cars?offset=1&color=red&limit=5>; rel=\"previous\",<http://controllerdemo-danbev.rhcloud.com/aerogear-controller-demo/cars?offset=11&color=red&limit=5>; rel=\"next\""
            };

            // mock up response body
            response = @[
                    @{@"id":@"1", @"color":@"red", @"type":@"bmv"},
                    @{@"id":@"2", @"color":@"red", @"type":@"seat"}
            ];
        });

        beforeEach(^{
            extractor = [[AGPageWebLinkingExtractor alloc] init];
        });

        it(@"should not be nil", ^{
            [extractor shouldNotBeNil];
        });

        it(@"should have 'previous' and 'next' values set if the next and prev params are valid", ^{
            NSDictionary *parsedInfo = [extractor parse:response
                                                headers:headers
                                                   next:NEXT_PAGE_IDENTIFIER
                                                   prev:PREVIOUS_PAGE_IDENTIFIER];
            [[parsedInfo should] haveCountOf:2];
        });

        it(@"should have 'previous' value only set if the next param is bogus", ^{
            NSDictionary *parsedInfo = [extractor parse:response
                                                headers:headers
                                                   next:@"bogus_next"
                                                   prev:PREVIOUS_PAGE_IDENTIFIER];
            [[parsedInfo should] haveCountOf:1];

            [[parsedInfo valueForKey:NEXT_PAGE_IDENTIFIER] shouldBeNil];
        });

        it(@"should have 'next' value only set if the prev param is bogus", ^{
            NSDictionary *parsedInfo = [extractor parse:response
                                                headers:headers
                                                   next:NEXT_PAGE_IDENTIFIER
                                                   prev:@"bogus_prev"];
            [[parsedInfo should] haveCountOf:1];

            [[parsedInfo valueForKey:PREVIOUS_PAGE_IDENTIFIER] shouldBeNil];
        });

        it(@"the parsed object should be empty if the prev and next params are bogus", ^{
            NSDictionary *parsedInfo = [extractor parse:response
                                                headers:headers
                                                   next:@"bogus_next"
                                                   prev:@"bogus_prev"];
            [[parsedInfo should] haveCountOf:0];

            [[parsedInfo valueForKey:PREVIOUS_PAGE_IDENTIFIER] shouldBeNil];
            [[parsedInfo valueForKey:NEXT_PAGE_IDENTIFIER] shouldBeNil];
        });
    });
});

SPEC_END