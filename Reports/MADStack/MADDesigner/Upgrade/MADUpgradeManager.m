//
//  MADUpgradeManager.m
//  MAD
//
//  Created by Michael Thomason on 9/12/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADUpgradeManager.h"
#import "MADOperationInstallSampleDatabase.h"
//#import <MADFoundation/MADApplicationProtocol.h>
//#import <MADFoundation/MADAppDelegate.h>
#import <MADFoundation/UIApplication+MADAppDelegate.h>

#define MADUPGRADE_CREATE_SAMPLE FALSE       //Not for production use.

NSString * const MADUpgradeLastVersionRun           = @"MADUpgradeLastVersionRun";
NSString * const MADIdentifierSegueUpgradeComplete  = @"MTSegueUpgradeComplete";
NSString * const MADIdentifierSegueUpgradeUnneeded  = @"MTSegueUpgradeUnneeded";

const char * queueUpgrade = "com.everdayapps.mad.upgrade";

const NSInteger currentMajorVersion = 8;

@implementation MADUpgradeManager

- (void)performUpgradeIfRequired:(void(^)(BOOL success, NSError *error, BOOL upgradePerformed))completion {
    BOOL upgradeRequired = NO;
    BOOL upgradeVersion7 = NO;
    BOOL installChinook = NO;
    BOOL installSamples = NO;
    
    NSUserDefaults *standardUserDefault = [NSUserDefaults standardUserDefaults];
    NSNumber *lastVersionRun = [standardUserDefault objectForKey:MADUpgradeLastVersionRun];
    
    NSURL *chinookUrl = [MADOperationInstallSampleDatabase applicationSupportSampleDatabaseChinook];
    BOOL isDirectory;
    BOOL gotChinook = [[NSFileManager defaultManager] fileExistsAtPath:chinookUrl.path isDirectory:&isDirectory];
    if (gotChinook == NO) {
        installChinook = YES;
    } else {
        installChinook = NO;
    }
    
    if ([MADApplication isMADDesigner]) {
        NSNumber *samplesInstalled = [standardUserDefault objectForKey:MADUpgradeInstalledSamples];
        if (samplesInstalled == nil) {
            installSamples = YES;
        } else {
            installSamples = NO;
        }
    } else {
        installSamples = NO;
    }
    
    if (lastVersionRun == nil) lastVersionRun = @(1);
    if (lastVersionRun.integerValue < currentMajorVersion) {
        
        if (lastVersionRun.integerValue <= 1) {
            upgradeRequired = YES;
            //upgradeVersion1 = YES;
        } else if (lastVersionRun.integerValue <= 7) {
            upgradeRequired = YES;
            upgradeVersion7 = YES;
        }
    }
    
    NSNumber *majorVersion = @(currentMajorVersion);
    [standardUserDefault setObject: majorVersion forKey: MADUpgradeLastVersionRun];
    
    if (installChinook || installSamples) {
        completion (YES, nil, YES);
    } else {
        completion (YES, nil, NO);
    }

}

@end
