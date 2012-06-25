//
//  BitweaverAppDelegate.h
//  Bitweaver API Demo
//
//  Copyright (c) 2012 Bitweaver.org. All rights reserved.
//

// Forward declare BitweaverUser as it requires AppDelegate
@class BitweaverUser;

#import <UIKit/UIKit.h>
#import "BitweaverUser.h"

@interface BitweaverAppDelegate : UIResponder <UIApplicationDelegate> {
}

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic, readonly) BitweaverUser *user;
@property (strong, nonatomic, readonly) NSString *apiBaseUri;

@property (nonatomic, retain) NSString *authLogin;
@property (nonatomic, retain) NSString *authPassword;

@end
