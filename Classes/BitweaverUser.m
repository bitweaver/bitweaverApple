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
@synthesize uuUserId;
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

- (NSDictionary*)getReceivablePropertyMappings {  
    NSMutableDictionary *mappings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     @"dateCreated",@"date_created",
                                     @"dateLastModified",@"date_last_modified", 
                                     nil
                                     ];
    [mappings addEntriesFromDictionary:[self getSendablePropertyMappings]];
    return mappings;
}

- (NSDictionary*)getSendablePropertyMappings {  
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @"userId",@"user_id",
            @"contentId",@"content_id",
            @"email",@"email",
            @"login",@"login",
            @"realName",@"real_name", 
            @"lastLogin",@"last_login", 
            @"currentLogin",@"current_login", 
            @"registrationDate",@"registration_date", 
            @"challenge",@"challenge", 
            @"passDue",@"pass_due", 
            @"uuUserId",@"uu_user_id", 
            @"user",@"user", 
            @"valid",@"valid", 
            @"isRegistered",@"is_registered", 
            @"portraitPath",@"portrait_path", 
            @"portraitUrl",@"portrait_url", 
            @"avatarPath",@"avatar_path", 
            @"avatarUrl",@"avatar_url", 
            @"logoPath",@"logo_path", 
            @"logoUrl",@"logo_url", 
            nil];  
}  


- (BOOL)verifyAuthentication:(id)callbackObject callbackMethod:(SEL)callbackMethod callbackParameter:(id)callbackParameter {
    if( ![self isAuthenticated] ) {
        [APPDELEGATE showAuthenticationDialog];
    }
    return [self isAuthenticated];
}

- (void)registerUser:(NSString*)authLogin withPassword:(NSString*)authPassword {
   
    /*
     NSDictionary *userDict = [NSDictionary dictionaryWithObjectsAndKeys:
     authLogin, @"email",
     authPassword, @"password",
     nil];
     [[RKClient sharedClient] put:@"users" params:userDict delegate:self];
     */
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
    NSDictionary *properties = [self getReceivablePropertyMappings];
    for (NSString* key in properties ) {
        [self setValue:nil forKey:key];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UserUnloaded" object:self];
    
}



@end
