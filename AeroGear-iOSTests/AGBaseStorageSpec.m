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
#import "AGBaseStorage.h"

SPEC_BEGIN(AGBaseStorageSpec)

describe(@"AGBaseStorage", ^{

    context(@"testing static utility methods", ^{

        it(@"should retrieve the url for the given filename", ^{
            NSURL *path = [AGBaseStorage storeURLWithName:@"filename"];

            [path shouldNotBeNil];
            [[path.lastPathComponent should] equal:@"filename"];
        });
        
        it(@"should fail if the filename is nil", ^{
            NSURL *path = [AGBaseStorage storeURLWithName:nil];
            
            [path shouldBeNil];
        });
    });
});

SPEC_END