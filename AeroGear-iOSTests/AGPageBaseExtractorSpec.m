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
#import <XCTest/XCTest.h>

#import "AGPageBaseExtractor.h"

/**
 * mocked impl to test AGPageBaseExtractor base class
 * concrete implementation methods.
 */
@interface AGMockedPageExtractor2: AGPageBaseExtractor
@end

@implementation AGMockedPageExtractor2
@end

@interface AGPageBaseExtractorTests : XCTestCase

@end

SPEC_BEGIN(AGPageBaseExtractorSpec)

describe(@"AGPageBaseExtractor", ^{
    context(@"when newly created", ^{

        __block AGMockedPageExtractor2 *extractor = nil;

        beforeEach(^{
            extractor = [[AGMockedPageExtractor2 alloc] init];
        });

        it(@"should not be nil", ^{
            [extractor shouldNotBeNil];
        });

        it(@"should be empty when query string is nil", ^{
            NSDictionary *parsedQuery = [extractor transformQueryString:nil];
            [[parsedQuery should] haveCountOf:0];
        });

        it(@"should transform query string when it has two args", ^{
            NSDictionary *parsedQuery = [extractor transformQueryString:@"foo=1&bar=2"];
            [[parsedQuery should] haveCountOf:2];
        });

        it(@"should transform query string when it has two args and a resource", ^{
            NSDictionary *parsedQuery = [extractor transformQueryString:@"cars?foo=1&bar=2"];
            [[parsedQuery should] haveCountOf:2];
        });

        it(@"should transform query string when it has two args and a leading question mark", ^{
            NSDictionary *parsedQuery = [extractor transformQueryString:@"?foo=1&bar=2"];
            [[parsedQuery should] haveCountOf:2];
        });
    });
});

SPEC_END