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
#import "AGPipeline.h"
#import "AGPipe.h"
#import "AGAuthenticator.h"

SPEC_BEGIN(AGPipelineSpec)

describe(@"AGPipeline", ^{
    context(@"when newly created", ^{
        
        __block AGPipeline *pipeline = nil;
        
        beforeEach(^{
            pipeline = [AGPipeline pipelineWithBaseURL:[NSURL URLWithString:@"http://server.com/"]];
        });
        
        it(@"should not be nil", ^{
            [pipeline shouldNotBeNil];
        });

        it(@"AGPipe should have an expected URL", ^{

            [pipeline pipe:^(id<AGPipeConfig> config) {
                [config setName:@"tests"];
            }];

            id<AGPipe> pipe =  [pipeline pipeWithName:@"tests"];
            [pipe.URL shouldNotBeNil];
            // does it match ?
            [[pipe.URL should] equal:[NSURL URLWithString:@"http://server.com/tests"]];
        });

        it(@"AGPipe should have a default type", ^{
            [pipeline pipe:^(id<AGPipeConfig> config) {
                [config setName:@"tests"];
            }];

            id<AGPipe> pipe = [pipeline pipeWithName:@"tests"];

            [(id)pipe shouldNotBeNil];
            [[pipe.type should] equal:@"REST"];
        });

        it(@"AGPipeline should allow add of an AGPipe object with valid type", ^{
            [pipeline pipe:^(id<AGPipeConfig> config) {
                [config setName:@"tests"];
                [config setType:@"REST"];
            }];

            id<AGPipe> pipe = [pipeline pipeWithName:@"tests"];

            [(id)pipe shouldNotBeNil];
            [[pipe.type should] equal:@"REST"];
        });

        it(@"AGPipeline should _not_ allow add of an AGPipe object with invalid type", ^{
            pipeline = [AGPipeline pipeline];
            [pipeline pipe:^(id<AGPipeConfig> config) {
                [config setName:@"tests"];
                [config setType:@"BOGUS"];
            }];

            id<AGPipe> pipe = [pipeline pipeWithName:@"tests"];
            [(id)pipe shouldBeNil];
        });

        it(@"AGPipeline should allow add of an AGPipe object with a different baseURL", ^{

            [pipeline pipe:^(id<AGPipeConfig> config) {
                [config setName:@"tasks"];
                [config setBaseURL:[NSURL URLWithString:@"http://blah.com/context"]];
            }];

            id<AGPipe> pipe = [pipeline pipeWithName:@"tasks"];
            [pipe.URL shouldNotBeNil];
            [[pipe.URL should] equal:[NSURL URLWithString:@"http://blah.com/context/tasks"]];
        });

        it(@"AGPipeline should allow add of an AGPipe object with a different endpoint", ^{

            [pipeline pipe:^(id<AGPipeConfig> config) {
                [config setName:@"tasks"];
                [config setEndpoint:@"myTasks"];
            }];

            id<AGPipe> pipe = [pipeline pipeWithName:@"tasks"];
            [pipe.URL shouldNotBeNil];
            [[pipe.URL should] equal:[NSURL URLWithString:@"http://server.com/myTasks"]];
        });

        it(@"AGPipeline should allow add of an AGPipe object with a different baseURL and an endpoint", ^{

            [pipeline pipe:^(id<AGPipeConfig> config) {
                [config setName:@"tasks"];
                [config setBaseURL:[NSURL URLWithString:@"http://blah.com/context"]];
                [config setEndpoint:@"myTasks"];
            }];

            id<AGPipe> pipe = [pipeline pipeWithName:@"tasks"];
            [pipe.URL shouldNotBeNil];
            [[pipe.URL should] equal:[NSURL URLWithString:@"http://blah.com/context/myTasks"]];
        });

        it(@"AGPipeline should allow to add multiple AGPipe objects with different baseURLs and replace previous ones", ^{
            // vanilla
            [pipeline pipe:^(id<AGPipeConfig> config) {
                [config setName:@"tasks"];
            }];

            id<AGPipe> newPipe = [pipeline pipeWithName:@"tasks"];
            [newPipe.URL shouldNotBeNil];
            [[newPipe.URL should] equal:[NSURL URLWithString:@"http://server.com/tasks"]];

            // new pipe, with different baseURL:
            [pipeline pipe:^(id<AGPipeConfig> config) {
                [config setName:@"projects"];
                [config setBaseURL:[NSURL URLWithString:@"http://blah.com/context"]];
            }];

            id<AGPipe> otherPipe = [pipeline pipeWithName:@"projects"];
            [otherPipe.URL shouldNotBeNil];
            [[otherPipe.URL should] equal:[NSURL URLWithString:@"http://blah.com/context/projects"]];

            // yet another new pipe, but replace the 'tasks' pipe (even it has a different URL):
            NSURL* secondBaseURL = [NSURL URLWithString:@"http://blah.com/somecontext"];
            [pipeline pipe:^(id<AGPipeConfig> config) {
                [config setName:@"tasks"];
                [config setBaseURL:secondBaseURL];
                [config setEndpoint:@"tags"];
            }];

            id<AGPipe> newestPipe = [pipeline pipeWithName:@"tasks"];
            [newestPipe.URL shouldNotBeNil];
            [[newestPipe.URL should] equal:[NSURL URLWithString:@"http://blah.com/somecontext/tags"]];
        });

        it(@"should be able to add and remove an AGPipe", ^{
            pipeline = [AGPipeline pipeline];

            // add 'tasks' pipe
            [pipeline pipe:^(id<AGPipeConfig> config) {
                [config setName:@"tests"];
                [config setBaseURL:[NSURL URLWithString:@"http://blah.com/context"]];
            }];

            id<AGPipe> pipe;

            pipe = [pipeline pipeWithName:@"tests"];
            [(id)pipe shouldNotBeNil];

            [pipeline remove:@"tests"];
            pipe = [pipeline pipeWithName:@"tests"];
            [(id)pipe shouldBeNil];
        });

        it(@"should not remove a non existing AGPipe", ^{
            pipeline = [AGPipeline pipeline];

            // add 'tasks' pipe
            [pipeline pipe:^(id<AGPipeConfig> config) {
                [config setName:@"tests"];
                [config setBaseURL:[NSURL URLWithString:@"http://blah.com/context"]];
            }];

            id<AGPipe> pipe;

            // remove non existing pipe
            pipe = [pipeline remove:@"FOO"];
            [(id) pipe shouldBeNil];

            // should contain the first pipe
            pipe = [pipeline pipeWithName:@"tests"];
            [(id)pipe shouldNotBeNil];
        });
    });
});

SPEC_END