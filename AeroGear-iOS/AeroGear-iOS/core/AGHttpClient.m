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

#import "AGHttpClient.h"
#import "AGMultipart.h"

#import <objc/runtime.h>

// useful macro to check iOS version
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

// -----------AFHTTPRequestOperation extension------------
// adds an associative reference to assign a timer with
// the operation. Will be used on success/failure callbacks
// to invalidate it.
@interface AFHTTPRequestOperation (Timeout)

// the timer associated with the operation
@property (nonatomic, retain) NSTimer* timer;

@end

static char const * const TimerTagKey = "TimerTagKey";

@implementation AFHTTPRequestOperation (Timeout)

@dynamic timer;

- (NSTimer*)timer {
    return objc_getAssociatedObject(self, TimerTagKey);
}

- (void)setTimer:(NSTimer*)timer {
    objc_setAssociatedObject(self, TimerTagKey, timer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
// -------------------------------------------------------

typedef void (^AGURLConnectionOperationProgressBlock)(NSUInteger bytes, long long totalBytes, long long totalBytesExpected);

@implementation AGHttpClient {
    // secs before a request timeouts (alternative name for primitive "double")
    NSTimeInterval _interval;
    
    AGURLConnectionOperationProgressBlock _uploadProgress;
}

+ (AGHttpClient *)clientFor:(NSURL *)url {
    return [[self alloc] initWithBaseURL:url timeout:60 /* the default timeout interval */];
}

+ (AGHttpClient *)clientFor:(NSURL *)url timeout:(NSTimeInterval)interval {
    return [[self alloc] initWithBaseURL:url timeout:interval];
}

- (id)initWithBaseURL:(NSURL *)url timeout:(NSTimeInterval)interval {
	
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    // set the timeout interval for requests
    _interval = interval;
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	[self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}

// override to manual schedule a timeout event.
// This is because for version of iOS < 6, if the timeout interval(for POST requests)
// is less than 240 secs, the interval is ignored.
// see https://devforums.apple.com/thread/25282?start=0&tstart=0
- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    
    NSURLRequest *request;
    
    if ([self hasMultipartData:parameters]) {
        NSError *error = nil;
        request = [self multipartFormRequestWithMethod:@"POST" path:path parameters:parameters error:&error];
        
        // if there was an error
        if (error) {
            failure(nil, error);
            return;
        }
    } else {
        request = [self requestWithMethod:@"POST" path:path parameters:parameters];
    }
    
    [self processRequest:request success:success failure:failure];
}

// override to manual schedule a timeout event.
// This is because for version of iOS < 6, if the timeout interval(for PUT requests)
// is less than 240 secs, the interval is ignored.
// see https://devforums.apple.com/thread/25282?start=0&tstart=0
- (void)putPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    
    NSURLRequest *request;
    
    if ([self hasMultipartData:parameters]) {
        NSError *error = nil;
        request = [self multipartFormRequestWithMethod:@"PUT" path:path parameters:parameters error:&error];
        
        // if there was an error
        if (error) {
            failure(nil, error);
            return;
        }
    } else {
        request = [self requestWithMethod:@"PUT" path:path parameters:parameters];
    }
    
    [self processRequest:request success:success failure:failure];
}

// override to add a request timeout interval
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters {
    // invoke the 'requestWithMethod:path:parameters:' from AFNetworking:
    NSMutableURLRequest* req = [super requestWithMethod:method path:path parameters:parameters];
    
    // set the timeout interval
    [req setTimeoutInterval:_interval];
    
    return req;
}

// construct a multi-part request
- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                                                  error:(NSError **) error {
    
    NSMutableURLRequest *req;
    
    // extract multipart data;
    NSMutableDictionary *parts = [[NSMutableDictionary alloc] init];
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj conformsToProtocol:@protocol(AGMultipart)]) {
            // add it
            [parts setObject:obj forKey:key];
        }  else if ([obj isKindOfClass:[NSURL class]]) { // TODO: deprecated
            obj = [[AGFilePart alloc] initWithFileURL:obj name:key];
            [parts setObject:obj forKey:key];
        }
    }];

    // cater for AFNetworking default behaviour to call [object description]
    // for parameters other than NSData and NSNull. We need to filter
    // AGMultipart objects from the request and apply them in the block later on
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [params removeObjectsForKeys:[parts allKeys]];
    
    __block NSError *err = nil;
    
    req = [self multipartFormRequestWithMethod:method path:path parameters:params
                     constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
                         
             [parts enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                 if ([obj isKindOfClass:[AGFilePart class]]) {
                     AGFilePart *part = (AGFilePart*)obj;
                     [formData appendPartWithFileURL:part.fileURL
                                                name:part.name
                                               error:&err];
                     
                     // if there was any error adding the
                     // file stop immediately
                     if (err)
                         *stop = YES;
                     
                 } else if ([obj isKindOfClass:[AGFileDataPart class]]) {
                     AGFileDataPart *part = (AGFileDataPart *)obj;
                     
                     [formData appendPartWithFileData:part.data
                                                 name:part.name
                                             fileName:part.fileName
                                             mimeType:part.mimeType];

                 } else if ([obj isKindOfClass:[AGStreamPart class]]) {
                     AGStreamPart *part = (AGStreamPart *)obj;
                     
                     [formData appendPartWithInputStream:part.inputStream
                                                    name:part.name
                                                fileName:part.fileName
                                                  length:part.length
                                                mimeType:part.mimeType];
                 }
             }];
        }];

    if (err) {
        *error = err;
        return nil;
    }

    // set the timeout interval
    [req setTimeoutInterval:_interval];
    
    return req;
}

- (void)setUploadProgressBlock:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))block {
    _uploadProgress = block;
}

// =====================================================
// =========== private utility methods  ================
// =====================================================

// Gateway of both postPath and putPath methods to schedule a POST/PUT http operation.
//
// This is needed, cause for those two requests, extra steps should be taken that
// will honour the timeout interval set in our AGPipeConfig (if running in versions of iOS < 6
// where the timeout interval less than 240sec is ignored)
//
// In particular for those versions we:
// - start a manual timer that upon fire will cancel the operation and invoke the client's failure block.
// - success/failure blocks are wrapped, so that the associative timer is invalidated upon completion of the request.
-(void)processRequest:(NSURLRequest*)request
              success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    
    AFHTTPRequestOperation* operation;
    
    // check if the ios version honours the timeout bug
    if (SYSTEM_VERSION_LESS_THAN(@"6.0")) {
        operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            // invalidate the timer associated with the operation
            [operation.timer invalidate];
            operation.timer = nil;
            
            success(operation, responseObject);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            // invalidate the timer associated with the operation
            [operation.timer invalidate];
            operation.timer = nil;
            
            failure(operation, error);
        }];
        
        // the block to be executed when timeout occurs
        //
        // Note: internally AF will invoke the 'failure' block
        //       with error code(-999, 'request couldn't be completed')
        void (^timeout)(void) = ^ {
            // cancel operation
            [operation cancel];
        };
        
        // associate the timer and schedule to run
        operation.timer = [NSTimer scheduledTimerWithTimeInterval:_interval
                                                           target:[NSBlockOperation blockOperationWithBlock:timeout]
                                                         selector:@selector(main)
                                                         userInfo:nil
                                                          repeats:NO];
    } else { // delegate the construction to AF
        operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    }
    
    if (_uploadProgress)
        [operation setUploadProgressBlock:_uploadProgress];
    
    [self enqueueHTTPRequestOperation:operation];
}

// extract any file objects(if any) embedded in the params
- (BOOL)hasMultipartData:(NSDictionary *)params {
    __block BOOL hasMultipart = NO;

    [[params allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj conformsToProtocol:@protocol(AGMultipart)] ||
            [obj isKindOfClass:[NSURL class]]) { // TODO: deprecated
            hasMultipart = YES;
            *stop = YES;
        }
    }];
    
    return hasMultipart;
}

@end
