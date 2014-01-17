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
#import "AGPageConfig.h"
#import "AGPageConfiguration.h"

SPEC_BEGIN(AGPageConfigSpec)

describe(@"AGPageConfigSpec", ^{
    context(@"when newly created", ^{
        
        //A pipe config object:
        __block AGPageConfiguration *config = nil;
        
        beforeEach(^{
            
            // empty object, with defaults:
            config = [[AGPageConfiguration alloc] init];
        });
        
        it(@"should not be nil", ^{
            [config shouldNotBeNil];
        });
        
        it(@"should have defaults", ^{
            [[config.metadataLocation should] equal:@"webLinking"];
            [[config.nextIdentifier should] equal:@"next"];
            [[config.previousIdentifier should] equal:@"previous"];
            [[config.offset should] equal:@"0"];
            [[theValue([config.limit integerValue]) should] equal:theValue(10)];
            
            
            // If no "parameter provider" has been provided, the values for
            // limit/offset are used
            [[config.parameterProvider objectForKey:@"limit"] shouldNotBeNil];
            [[config.parameterProvider objectForKey:@"offset"] shouldNotBeNil];
        });
        
        it(@"should allow overriding defaults", ^{
            
            // set up:
            config.metadataLocation = @"body";
            config.nextIdentifier = @"tw-next";
            config.previousIdentifier = @"tw-prev";
            config.parameterProvider = [NSDictionary dictionaryWithObjectsAndKeys:@"foo", @"key1", @"bar", @"key2", nil];
            
            [[config.metadataLocation should] equal:@"body"];
            [[config.nextIdentifier should] equal:@"tw-next"];
            [[config.previousIdentifier should] equal:@"tw-prev"];
            
            
            // If no "parameter provider" has been provided, the values for
            // limit/offset are used
            [[config.parameterProvider objectForKey:@"key1"] shouldNotBeNil];
            [[config.parameterProvider objectForKey:@"key1"] shouldNotBeNil];
            [[config.parameterProvider objectForKey:@"limit"] shouldBeNil];
            [[config.parameterProvider objectForKey:@"offset"] shouldBeNil];
        });
        
        it(@"should ignore bogus values", ^{
            
            // set up:
            config.metadataLocation = @"baar";
            
            // check:
            [[config.metadataLocation should] equal:@"webLinking"];
            
        });
    });
});

SPEC_END