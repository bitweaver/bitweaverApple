//
//  BitweaverUser.h
//  Bitweaver API Demo
//
//  Created by Christian Fowler on 2/4/12.
//  Copyright (c) 2012 Viovio.com. All rights reserved.
//

#import "LibertyBase.h"

@class BitweaverUser;

@interface BitweaverUser : LibertyBase {
}


@property (nonatomic, retain) NSString* email;
@property (nonatomic, retain) NSString* login;
@property (nonatomic, retain) NSString* realName;
@property (nonatomic, retain) NSString* lastLogin;
@property (nonatomic, retain) NSString* currentLogin;
@property (nonatomic, retain) NSString* registrationDate;
@property (nonatomic, retain) NSString* challenge;
@property (nonatomic, retain) NSString* passDue;
@property (nonatomic, retain) NSString* user;
@property (nonatomic, retain) NSString* valid;
@property (nonatomic, retain) NSString* isRegistered;
@property (nonatomic, retain) NSString* portraitPath;
@property (nonatomic, retain) NSString* portraitUrl;
@property (nonatomic, retain) NSString* avatarPath;
@property (nonatomic, retain) NSString* avatarUrl;
@property (nonatomic, retain) NSString* logoPath;
@property (nonatomic, retain) NSString* logoUrl;
@property (nonatomic, retain) NSString* firstName;
@property (nonatomic, retain) NSString* lastName;

- (NSDictionary*)getAllPropertyMappings;
- (NSDictionary*)getSendablePropertyMappings; 

- (BOOL)isAuthenticated;
- (BOOL)verifyAuthentication:(id)callbackObject callbackMethod:(SEL)callbackMethod callbackParameter:(id)callbackParameter;
- (void)registerUser:(NSString*)authLogin withPassword:(NSString*)authPassword;
- (void)authenticate:(NSString*)authLogin withPassword:(NSString*)authPassword;

@end
