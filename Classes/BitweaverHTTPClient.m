//
//  BitweaverHTTPClient.m
//  designer
//
//  Created by Christian Fowler on 4/9/12.
//  Copyright (c) 2012 Viovio.com. All rights reserved.
//

#import "BitweaverHTTPClient.h"
#import "AppDelegateConnector.h"

@implementation BitweaverHTTPClient

+ (BitweaverHTTPClient *) sharedClient {
    static BitweaverHTTPClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedClient = (BitweaverHTTPClient *)[super clientWithBaseURL:[NSURL URLWithString:APPDELEGATE.apiBaseUri]];
        NSAssert(_sharedClient, @"Shared REST client not initialized" );
    });
    
    [_sharedClient setAuthorizationHeaderWithUsername:APPDELEGATE.authLogin password:APPDELEGATE.authPassword];    
    return _sharedClient;
}

+ (NSMutableURLRequest *) requestWithPath:(NSString *)urlPath {

    NSMutableURLRequest *request = [[BitweaverHTTPClient sharedClient] requestWithMethod:@"GET" path:urlPath parameters:nil];
    [BitweaverHTTPClient prepareRequestHeaders:request];
    
    return request;
}

+ (void) prepareRequestHeaders:(NSMutableURLRequest *)request {
    [request setValue:[NSString stringWithFormat:@"API consumer_key=\"%@\"", APP_API_KEY] forHTTPHeaderField:@"API"];
}

+ (NSString *) errorMessageWithResponse:response urlRequest:(NSURLRequest *)request JSON:(NSDictionary *)JSON {
    
    NSMutableString *errorMessage = [NSMutableString string];
    for (NSString* key in [JSON allKeys] ) {
        [errorMessage appendFormat:@"%@\n", [JSON objectForKey:key]];
    }
    
    if( [errorMessage length] == 0 ) {
        if( [response statusCode] == 408 ) {
            [errorMessage appendString:@"Request timed out. Please check your internet connection."];
        } else {
            [errorMessage appendString:@"Unknown error."];
        }
    }

    return [NSString stringWithFormat:@"%@\n(ERR %d %@)", errorMessage, [response statusCode], request.URL.host];
}



@end
