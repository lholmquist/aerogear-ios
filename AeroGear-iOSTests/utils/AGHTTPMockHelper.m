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

#import "AGHTTPMockHelper.h"

@implementation AGHTTPMockHelper

static NSString* HTTPMethodCalled;
static NSDictionary* HTTPRequestHeaders;

+ (void)mockResponse:(NSData*)data {
    return [self mockResponse:data headers:nil status:200 responseTime:0];
}

+ (void)mockResponseTimeout:(NSData*)data status:(int)status responseTime:(NSTimeInterval)responseTime {
    return [self mockResponse:data headers:nil status:200 responseTime:responseTime];
}

+ (void)mockResponseHeaders:(NSData*)data headers:(NSDictionary*)headers {
    return [self mockResponse:data headers:headers status:200 responseTime:0];
}

+ (void)mockResponseStatus:(int)status {
    return [self mockResponse:[NSData data] headers:nil status:status responseTime:0];
}

+ (void)mockResponse:(NSData*)data
             headers:(NSDictionary*)appendHeaders
              status:(int)status
        responseTime:(NSTimeInterval)responseTime {
    
    NSMutableDictionary* headers = [NSMutableDictionary
                                    dictionaryWithObject:@"application/json; charset=utf-8" forKey:@"Content-Type"];

    if (appendHeaders != nil)
        [headers addEntriesFromDictionary:appendHeaders];
    
    
	[OHHTTPStubs addRequestHandler:^(NSURLRequest *request, BOOL onlyCheck) {
        HTTPMethodCalled = request.HTTPMethod;
        HTTPRequestHeaders = request.allHTTPHeaderFields;
        
        return [OHHTTPStubsResponse responseWithData:data
                                          statusCode:status
                                        responseTime:responseTime
                                             headers:headers];
	}];
}

+ (NSString*)lastHTTPMethodCalled {
    return HTTPMethodCalled;
}

+ (NSDictionary*)lastHTTPRequestHeaders {
    return HTTPRequestHeaders;
}

+ (void)clearAllMockedRequests {
    [OHHTTPStubs removeAllRequestHandlers];
    
    HTTPMethodCalled = nil;
    HTTPRequestHeaders = nil;
}

@end
