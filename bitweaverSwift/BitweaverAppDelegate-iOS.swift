//  Converted to Swift 4 by Swiftify v4.1.6809 - https://objectivec2swift.com/
//
//  BitweaverAppDelegate.swift
//  Bitweaver API Demo
//
//  Copyright (c) 2012 Bitweaver.org. All rights reserved.
//

// Forward declare BitweaverUser as it requires AppDelegate
//
//  BitweaverAppDelegate.swift
//  Bitweaver API Demo
//
//  Copyright (c) 2012 Bitweaver.org. All rights reserved.
//

import UIKit

class BitweaverAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private(set) var user: BitweaverUser?
    private(set) var apiBaseUri = ""
    var authLogin = ""
    var authPassword = ""

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil) -> Bool {
        // Override point for customization after application launch.
        if UIDevice.current.userInterfaceIdiom == .pad {
            //        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
            //        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
            //        splitViewController.delegate = (id)navigationController.topViewController;

            // Setup URI used for all REST calls
            if let bundleApiUri = Bundle.main.object(forInfoDictionaryKey: "BW_API_URI") as? String {
                apiBaseUri = bundleApiUri
            }

            user = BitweaverUser()
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        /*
             Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
             Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
             */
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        /*
             Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
             If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
             */
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        /*
             Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
             */
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        /*
             Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
             */
    }

    func applicationWillTerminate(_ application: UIApplication) {
        /*
             Called when the application is about to terminate.
             Save data if appropriate.
             See also applicationDidEnterBackground:.
             */
    }
}
