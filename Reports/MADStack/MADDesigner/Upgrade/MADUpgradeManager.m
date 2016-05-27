//
//  MADUpgradeManager.m
//  MAD
//
//  Created by Michael Thomason on 9/12/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADUpgradeManager.h"
#import "MADInstallOperationSampleDatabase.h"
#import <MADFoundation/UIApplication+MADAppDelegate.h>

#define MADUPGRADE_CREATE_SAMPLE FALSE       //Not for production use.

NSString * const MADUpgradeLastVersionRun           = @"MADUpgradeLastVersionRun";
NSString * const MADIdentifierSegueUpgradeComplete  = @"MTSegueUpgradeComplete";
NSString * const MADIdentifierSegueUpgradeUnneeded  = @"MTSegueUpgradeUnneeded";

const char * queueUpgrade = "com.everdayapps.mad.upgrade";

const NSInteger currentMajorVersion = 8;

@implementation MADUpgradeManager

- (void)performUpgradeIfRequired:(void(^)(BOOL success, NSError *error,
                                          BOOL upgradePerformed))completion {

    BOOL upgradeRequired = NO;
    BOOL upgradeVersion7 = NO;
    BOOL installChinook = NO;
    BOOL installSamples = NO;
    
    NSUserDefaults *standardUserDefault = [NSUserDefaults standardUserDefaults];
    NSNumber *lastVersionRun = [standardUserDefault objectForKey:MADUpgradeLastVersionRun];
    
    NSURL *dbURL;
    dbURL = [MADInstallOperationSampleDatabase newApplicationSupportSampleDatabaseChinook];
    BOOL isDirectory;
    NSString *path = dbURL.path;
    BOOL gotChinook = [[NSFileManager defaultManager] fileExistsAtPath: path
                                                           isDirectory: &isDirectory];
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
        } else if (lastVersionRun.integerValue <= 7) {
            upgradeRequired = YES;
            upgradeVersion7 = YES;
        }
    }
    
    NSNumber *majorVersion =  [[NSNumber alloc] initWithUnsignedInteger: currentMajorVersion];
    [standardUserDefault setObject: majorVersion forKey: MADUpgradeLastVersionRun];
    
    if (installChinook || installSamples) {
        completion (YES, nil, YES);
    } else {
        completion (YES, nil, NO);
    }

}

@end
