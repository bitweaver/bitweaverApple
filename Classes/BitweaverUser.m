//
//  BitweaverUser.m
//  AQGridView
//
//  Created by Christian Fowler on 1/28/12.
//  Copyright (c) 2012 Viovio.com. All rights reserved.
//

#import "BitweaverUser.h"
#import "AppDelegateConnector.h"
#import "BitweaverHTTPClient.h"

@implementation BitweaverUser

@synthesize userId;
@synthesize contentId;
@synthesize email;
@synthesize login;
@synthesize realName;
@synthesize lastLogin;
@synthesize currentLogin;
@synthesize registrationDate;
@synthesize challenge;
@synthesize passDue;
@synthesize user;
@synthesize valid;
@synthesize isRegistered;
@synthesize portraitPath;
@synthesize portraitUrl;
@synthesize avatarPath;
@synthesize avatarUrl;
@synthesize logoPath;
@synthesize logoUrl;
@synthesize firstName;
@synthesize lastName;

- (NSDictionary*)getAllPropertyMappings {  
    NSMutableDictionary *mappings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
             @"lastLogin",@"last_login", 
             @"currentLogin",@"current_login", 
             @"registrationDate",@"registration_date", 
             @"isRegistered",@"is_registered", 
             @"portraitPath",@"portrait_path", 
             @"portraitUrl",@"portrait_url", 
             @"avatarPath",@"avatar_path", 
             @"avatarUrl",@"avatar_url", 
             @"logoPath",@"logo_path", 
             @"logoUrl",@"logo_url", 
             nil
             ];
    [mappings addEntriesFromDictionary:[super getAllPropertyMappings]];
    return mappings;
}

- (NSDictionary*)getSendablePropertyMappings {  
    NSMutableDictionary *mappings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            @"email",@"email",
            @"login",@"login",
            @"realName",@"real_name", 
            @"user",@"user", 
            nil];  
    [mappings addEntriesFromDictionary:[super getSendablePropertyMappings]];
    return mappings;
}  


- (BOOL)verifyAuthentication:(id)object selectorName:(NSString*)selectorName callbackParameter:(id)callbackParameter {
    if( ![self isAuthenticated] ) {
        callbackObject = object;
        callbackSelectorName = selectorName;
        [APPDELEGATE showAuthenticationDialog];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [object performSelector:NSSelectorFromString(selectorName)];
#pragma clang diagnostic pop
    }
    return [self isAuthenticated];
}

- (void)registerUser:(NSString*)authLogin withPassword:(NSString*)authPassword {
    
    // Assume login was email field, update here for registration
    [self setValue:authLogin forKey:@"email"];
    
    NSDictionary *properties = [self getSendablePropertyMappings];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:[properties count]];
    for (NSString* key in [properties allKeys] ) {
        [parameters setValue:[self valueForKey:[properties objectForKey:key]] forKey:key];
    }
    [parameters setValue:authPassword forKey:@"password"];
    NSMutableURLRequest *putRequest = [[BitweaverHTTPClient sharedClient] multipartFormRequestWithMethod:@"POST" path:[NSString stringWithFormat:@"users"] parameters:parameters constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) { }];
    
    [BitweaverHTTPClient prepareRequestHeaders:putRequest];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:putRequest
success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
    [self loadFromRemoteProperties:JSON];
    [APPDELEGATE authenticationSuccess];
} 
failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
    [APPDELEGATE registrationFailure:[NSString stringWithFormat:@"Registration failed.\n\n%@", [BitweaverHTTPClient errorMessageWithResponse:response urlRequest:request JSON:JSON]]];
}
];
        
   [[[NSOperationQueue alloc] init] addOperation:operation];
}

- (void)authenticate:(NSString*)authLogin withPassword:(NSString*)authPassword {
    
    APPDELEGATE.authLogin = authLogin;
    APPDELEGATE.authPassword = authPassword;
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:[BitweaverHTTPClient requestWithPath:@"users/authenticate"]
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            // Set all cookies so subsequent requests pass on info
            NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:[NSURL URLWithString:APPDELEGATE.apiBaseUri]];
            
            for ( NSHTTPCookie* cookie in cookies ) {
                [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
            }
            
            [self loadFromRemoteProperties:JSON];
            [APPDELEGATE authenticationSuccess];
            
            // Send a notification event user has just logged in.
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UserLoaded" object:self];
            
            if( callbackSelectorName != nil ) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [callbackObject performSelector:NSSelectorFromString(callbackSelectorName)];
#pragma clang diagnostic pop
                callbackObject = nil;
                callbackSelectorName = nil;
            }            

        } 
        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        }
     ];
    
    [[[NSOperationQueue alloc] init] addOperation:operation];
}

- (BOOL)isAuthenticated {
    return (self.userId != nil);
}

- (void)logout {
    APPDELEGATE.authLogin = nil;
    APPDELEGATE.authPassword = nil;
    NSDictionary *properties = [self getAllPropertyMappings];
    for (NSString* key in properties ) {
        [self setValue:nil forKey:key];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UserUnloaded" object:self];
    
}



@end
