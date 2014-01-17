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
#import "AGAuthenticator.h"

SPEC_BEGIN(AGAuthenticatorSpec)

describe(@"AGAuthenticator", ^{
    context(@"when newly created", ^{

        __block AGAuthenticator *authenticator = nil;

        beforeEach(^{
            authenticator = [AGAuthenticator authenticator];
        });

        it(@"should not be nil", ^{
            [authenticator shouldNotBeNil];
        });
    });

    context(@"when adding a new module", ^{

        __block AGAuthenticator *authenticator = nil;

        beforeEach(^{
            authenticator = [AGAuthenticator authenticator];
        });

        it(@"should have default endpoints if not specified", ^{
            id<AGAuthenticationModule> module = [authenticator auth:^(id<AGAuthConfig> config) {
                [config setName:@"SomeModule"];
                [config setBaseURL:[NSURL URLWithString:@"https://server:8080/application/"]];
            }];

            [(id)module shouldNotBeNil];

            [[module.loginEndpoint should] equal:@"https://server:8080/application/auth/login"];
            [[module.logoutEndpoint should] equal:@"https://server:8080/application/auth/logout"];
            [[module.enrollEndpoint should] equal:@"https://server:8080/application/auth/enroll"];
        });

        it(@"should respect user-configured endpoints", ^{
            id<AGAuthenticationModule> module =  [authenticator auth:^(id<AGAuthConfig> config) {
                [config setName:@"SomeModule"];
                [config setBaseURL:[NSURL URLWithString:@"https://server:8080/application/subcontext/"]];
                [config setLoginEndpoint:@"auth/in"];
                [config setLogoutEndpoint:@"auth/out"];
                [config setEnrollEndpoint:@"auth/register"];
            }];

            [(id)module shouldNotBeNil];

            [[module.loginEndpoint should] equal:@"https://server:8080/application/subcontext/auth/in"];
            [[module.logoutEndpoint should] equal:@"https://server:8080/application/subcontext/auth/out"];
            [[module.enrollEndpoint should] equal:@"https://server:8080/application/subcontext/auth/register"];
        });

        it(@"should have a default type if not specified", ^{
            id<AGAuthenticationModule> module = [authenticator auth:^(id<AGAuthConfig> config) {
                [config setName:@"SomeModule"];
                [config setBaseURL:[NSURL URLWithString:@"https://server:8080/application/"]];
            }];

            [(id)module shouldNotBeNil];

            [[module.type should] equal:@"AG_SECURITY"];
        });

        it(@"should not allow an invalid type", ^{
            id<AGAuthenticationModule> module = [authenticator auth:^(id<AGAuthConfig> config) {
                [config setName:@"SomeModule"];
                [config setBaseURL:[NSURL URLWithString:@"https://server:8080/application/"]];
                [config setType:@"INVALID"];
            }];

            [(id)module shouldBeNil];
        });
    });

    context(@"when adding and removing modules", ^{

        __block AGAuthenticator *authenticator = nil;

        beforeEach(^{
            authenticator = [AGAuthenticator authenticator];
        });

        it(@"should successfully remove previously added modules", ^{
            id<AGAuthenticationModule> module = [authenticator auth:^(id<AGAuthConfig> config) {
                [config setName:@"SomeModule"];
                [config setBaseURL:[NSURL URLWithString:@"https://server:8080/application/"]];
            }];

            [(id)module shouldNotBeNil];

            id<AGAuthenticationModule> otherModule = [authenticator auth:^(id<AGAuthConfig> config) {
                [config setName:@"OtherModule"];
                [config setBaseURL:[NSURL URLWithString:@"https://server:8080/another-application/"]];
            }];

            [(id)otherModule shouldNotBeNil];

            // look em up:
            [(id)[authenticator authModuleWithName:@"SomeModule"] shouldNotBeNil];
            [(id)[authenticator authModuleWithName:@"OtherModule"] shouldNotBeNil];

            // remove module
            [authenticator remove:@"SomeModule"];
            // look it up:
            [(id)[authenticator authModuleWithName:@"SomeModule"] shouldBeNil];

            // remove module
            [authenticator remove:@"OtherModule"];
            // look it up:
            [(id)[authenticator authModuleWithName:@"OtherModule"] shouldBeNil];
        });

        it(@"should not remove a non existing module", ^{
            id<AGAuthenticationModule> module = [authenticator auth:^(id<AGAuthConfig> config) {
                [config setName:@"SomeModule"];
                [config setBaseURL:[NSURL URLWithString:@"https://server:8080/application/"]];
            }];

            [(id)module shouldNotBeNil];

            // remove non existing module
            id<AGAuthenticationModule> fooModule = [authenticator remove:@"FOO"];
            [(id)fooModule shouldBeNil];

            // should contain the first module
            module = [authenticator authModuleWithName:@"SomeModule"];
            [(id)module shouldNotBeNil];
        });

        it(@"should not fail when you lookup a non existing module", ^{
            // lookup non existing module
            id<AGAuthenticationModule> fooModule = [authenticator authModuleWithName:@"FOO"];
            [(id)fooModule shouldBeNil];
        });
    });
});

SPEC_END