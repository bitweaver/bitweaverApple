//
//  BitweaverHTTPClient.h
//  designer
//
//  Created by Christian Fowler on 4/9/12.
//  Copyright (c) 2012 Viovio.com. All rights reserved.
//

#import "AFNetworking.h"
#import "AFHTTPClient.h"

@interface BitweaverHTTPClient : AFHTTPClient

+ (BitweaverHTTPClient *) sharedClient;
+ (NSMutableURLRequest *) requestWithPath:(NSString *)urlPath;
+ (void) prepareRequestHeaders:(NSMutableURLRequest *)request;
+ (NSString *) errorMessageWithResponse:response urlRequest:(NSURLRequest *)request JSON:(NSDictionary *)JSON;

@end
