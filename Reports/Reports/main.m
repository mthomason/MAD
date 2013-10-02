//
//  main.m
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

int main(int argc, char *argv[]) {
    @autoreleasepool {
        
        //Per WWDC 2013 session 308, at 34:30 minute marker,
        //  they say to validate the receipt "way before you get
        //  anywhere near UIApplication... do it in the main run-
        //  loop."
        [MTVerificationController sharedInstance];
        
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
