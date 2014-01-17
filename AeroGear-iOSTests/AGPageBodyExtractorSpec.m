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

#import "AGPageBodyExtractor.h"

SPEC_BEGIN(AGPageBodyExtractorSpec)

describe(@"AGPageBodyExtractor", ^{
    context(@"when newly created", ^{

        __block NSString *NEXT_PAGE_IDENTIFIER = nil;
        __block NSString *PREVIOUS_PAGE_IDENTIFIER = nil;

        __block NSDictionary *headers = nil;
        __block NSDictionary *response = nil;

        __block AGPageBodyExtractor *extractor = nil;

        beforeAll(^{
            // default names for paging
            NEXT_PAGE_IDENTIFIER = @"next_page";
            PREVIOUS_PAGE_IDENTIFIER = @"previous_page";

            // mock up response headers
            headers = @{@"status"        : @"200 OK",
                    @"cache-control" : @"max-age=15, must-revalidate, max-age=300",
                    @"content-type"  : @"application/json;charset=utf-8"};

            // mock up 'body' paging response (extracted from twitter)
            response = @{@"query"         : @"aerogear",
                    @"refresh_url"   : @"?since_id=323898917563543552&q=aerogear",
                    @"next_page"     : @"?page=3&max_id=323898917563543552&q=aerogear&rpp=1",
                    @"previous_page" : @"?page=1&max_id=323898917563543552&q=aerogear&rpp=1"
            };
        });

        beforeEach(^{
            extractor = [[AGPageBodyExtractor alloc] init];
        });

        it(@"should not be nil", ^{
            [extractor shouldNotBeNil];
        });

        it(@"the parsed object should be nil when the body arg is nil", ^{
            NSDictionary *parsedInfo = [extractor parse:nil
                                                headers:headers
                                                   next:NEXT_PAGE_IDENTIFIER
                                                   prev:PREVIOUS_PAGE_IDENTIFIER];

            [parsedInfo shouldBeNil];
        });

        it(@"the parsed object should be nil when the body arg is an Array", ^{
            NSDictionary *parsedInfo = [extractor parse:[NSArray array]
                                                 headers:headers
                                                    next:NEXT_PAGE_IDENTIFIER
                                                    prev:PREVIOUS_PAGE_IDENTIFIER];

            [parsedInfo shouldBeNil];
        });

        it(@"the parsed object should be nil when the body arg is a String", ^{
            NSDictionary *parsedInfo = [extractor parse:@"bogus"
                                                headers:headers
                                                   next:NEXT_PAGE_IDENTIFIER
                                                   prev:PREVIOUS_PAGE_IDENTIFIER];

            [parsedInfo shouldBeNil];
        });

        it(@"the parsed object should be empty when the body arg is an empty dictionary", ^{
            NSDictionary *parsedInfo = [extractor parse:[NSDictionary dictionary]
                                                headers:headers
                                                   next:NEXT_PAGE_IDENTIFIER
                                                   prev:PREVIOUS_PAGE_IDENTIFIER];

            [[parsedInfo should] haveCountOf:0];
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
                                                   prev:@"bogus"];
            [[parsedInfo should] haveCountOf:1];

            [[parsedInfo valueForKey:PREVIOUS_PAGE_IDENTIFIER] shouldBeNil];
        });

        it(@"the parsed object should be empty if the prev and next params are bogus", ^{
            NSDictionary *parsedInfo = [extractor parse:response
                                                headers:headers
                                                   next:@"bogus"
                                                   prev:@"bogus"];
            [[parsedInfo should] haveCountOf:0];

            [[parsedInfo valueForKey:PREVIOUS_PAGE_IDENTIFIER] shouldBeNil];
            [[parsedInfo valueForKey:NEXT_PAGE_IDENTIFIER] shouldBeNil];
        });
    });
});

SPEC_END