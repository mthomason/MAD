//
//  main.m
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"
#import "MTVerificationController.h"

int main(int argc, char *argv[]) {
    @autoreleasepool {
        
        //Per WWDC 2013 session 308, at 34:30 minute marker,
        //  they say to validate the receipt "way before you get
        //  anywhere near UIApplication... do it in the main run-
        //  loop."
        
        // FIXME: Only do this when you are going to disable some feature for copy protection
        //          Right now it's just a pain in the ass.
        //[MTVerificationController sharedInstance];
        
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
