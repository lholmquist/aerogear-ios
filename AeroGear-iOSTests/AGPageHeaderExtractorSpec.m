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

#import "AGPageHeaderExtractor.h"

SPEC_BEGIN(AGPageHeaderExtractorSpec)

describe(@"AGPageHeaderExtractor", ^{
    context(@"when newly created", ^{

        __block NSString *NEXT_PAGE_IDENTIFIER = nil;
        __block NSString *PREVIOUS_PAGE_IDENTIFIER = nil;

        __block NSDictionary *headers = nil;
        __block NSArray      *response = nil;

        __block AGPageHeaderExtractor *extractor = nil;

        beforeAll(^{
            // default names for paging
            NEXT_PAGE_IDENTIFIER = @"AG-Links-Next";
            PREVIOUS_PAGE_IDENTIFIER = @"AG-Links-Previous";

            // mock up paging response headers (extracted from AGController)
            headers = @{
                    @"AG-Links-Next" : @"http://controllerdemo-danbev.rhcloud.com/aerogear-controller-demo/cars-custom?offset=11&color=red&limit=5",
                    @"AG-Links-Previous" : @"http://controllerdemo-danbev.rhcloud.com/aerogear-controller-demo/cars-custom?offset=1&color=red&limit=5"
            };

            // mock up response body
            response = @[
                    @{@"id":@"1", @"color":@"red", @"type":@"bmv"},
                    @{@"id":@"2", @"color":@"red", @"type":@"seat"}
            ];
        });

        beforeEach(^{
            extractor = [[AGPageHeaderExtractor alloc] init];
        });

        it(@"should not be nil", ^{
            [extractor shouldNotBeNil];
        });

        it(@"the parsed object should be nil when the headers arg is nil", ^{
            NSDictionary *parsedInfo = [extractor parse:response
                                                headers:nil
                                                   next:NEXT_PAGE_IDENTIFIER
                                                   prev:PREVIOUS_PAGE_IDENTIFIER];

            [parsedInfo shouldBeNil];
        });

        it(@"the parsed object should be empty when the headers arg is an empty dictionary", ^{
            NSDictionary *parsedInfo = [extractor parse:response
                                                headers:@{}
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
                                                   next:@"AG-Bogus-Next"
                                                   prev:PREVIOUS_PAGE_IDENTIFIER];
            [[parsedInfo should] haveCountOf:1];

            [[parsedInfo valueForKey:NEXT_PAGE_IDENTIFIER] shouldBeNil];
        });

        it(@"should have 'next' value only set if the prev param is bogus", ^{
            NSDictionary *parsedInfo = [extractor parse:response
                                                headers:headers
                                                   next:NEXT_PAGE_IDENTIFIER
                                                   prev:@"AG-Bogus-Previous"];
            [[parsedInfo should] haveCountOf:1];

            [[parsedInfo valueForKey:PREVIOUS_PAGE_IDENTIFIER] shouldBeNil];
        });

        it(@"the parsed object should be empty if the prev and next params are bogus", ^{
            NSDictionary *parsedInfo = [extractor parse:response
                                                headers:headers
                                                   next:@"AG-Bogus-Next"
                                                   prev:@"AG-Bogus-Previous"];
            [[parsedInfo should] haveCountOf:0];

            [[parsedInfo valueForKey:PREVIOUS_PAGE_IDENTIFIER] shouldBeNil];
            [[parsedInfo valueForKey:NEXT_PAGE_IDENTIFIER] shouldBeNil];
        });
    });
});

SPEC_END