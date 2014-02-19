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

typedef void (^AGURLConnectionOperationProgressBlock)(NSUInteger bytes, long long totalBytes, long long totalBytesExpected);

@implementation AGHttpClient {
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

// override to construct a multipart request if required by the params passed in
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

// override to construct a multipart request if required by the params passed in
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

-(void)processRequest:(NSURLRequest*)request
              success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {

    AFHTTPRequestOperation* operation;

    operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];

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