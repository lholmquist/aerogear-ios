/*
 * JBoss, Home of Professional Open Source
 * Copyright 2012, Red Hat, Inc., and individual contributors
 * by the @authors tag. See the copyright.txt in the distribution for a
 * full listing of individual contributors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


#import <SenTestingKit/SenTestingKit.h>
#import "AGRestAuthentication.h"

@interface AGRestAuthenticationTests : SenTestCase

@end

@implementation AGRestAuthenticationTests{
    BOOL _finishedFlag;
    AGRestAuthentication* restAuthModule;
}
-(void)setUp {
    [super setUp];
    // create a shared client for the demo app:
    //NSURL* baseURL = [NSURL URLWithString:@"http://localhost:8080/todo-server/"];
    NSURL* baseURL = [NSURL URLWithString:@"https://todoauth-aerogear.rhcloud.com/todo-server/"];
    restAuthModule = [AGRestAuthentication moduleForBaseURL:baseURL];

    _finishedFlag = NO;
}

-(void)tearDown {
    restAuthModule = nil;
}

///////// this is more an integration test......


-(void) testSuccessfulLogin {
    
    [restAuthModule login:@"john" password:@"123" success:^(id object) {
        _finishedFlag = YES;
    } failure:^(NSError *error) {
        _finishedFlag = YES;
        STFail(@"wrong login");
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void) testUnsuccessfulLogin {

    [restAuthModule login:@"johnny" password:@"likeAboss" success:^(id object) {
        STFail(@"should not work...");
        _finishedFlag = YES;
    } failure:^(NSError *error) {
        _finishedFlag = YES;
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}


-(void) testLogoff {
    
    [restAuthModule login:@"john" password:@"123" success:^(id object) {
        // after initial login, we issue a logout:
        [restAuthModule logout:^{
            _finishedFlag = YES;
        } failure:^(NSError *error) {
            _finishedFlag = YES;
            STFail(@"wrong logout...");
        }];
    } failure:^(NSError *error) {
        _finishedFlag = YES;
        STFail(@"wrong login");
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}


-(void) testWrongLogoff {
    
    // blank logoff....
    [restAuthModule logout:^{
        _finishedFlag = YES;
        STFail(@"this should fail, so no success should be invoked");
    } failure:^(NSError *error) {
        _finishedFlag = YES;
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

// not testing this, need to generate random usernames...
-(void) xytestRegister {
    // {"firstname":"firstname","lastname":"lastname","email":"mei@ooo.de","username":"dsadsasdas","password":"asdasdasdsa","role":"admin"}
    NSMutableDictionary* registerPayload = [NSMutableDictionary dictionary];
    [registerPayload setValue:@"Matthias" forKey:@"firstname"];
    [registerPayload setValue:@"Wessendorf" forKey:@"lastname"];
    [registerPayload setValue:@"emaadsil@mssssse.com" forKey:@"email"];
    [registerPayload setValue:@"usefhrndasame" forKey:@"username"];
    [registerPayload setValue:@"secASDret" forKey:@"password"];
    [registerPayload setValue:@"admin" forKey:@"role"];
    
    [restAuthModule enroll:registerPayload success:^(id object) {
        NSLog(@"\n\n%@", object);
        _finishedFlag = YES;
    } failure:^(NSError *error) {
        NSLog(@"\n\n%@", error);
        _finishedFlag = YES;
        STFail(@"broken register");
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}



@end