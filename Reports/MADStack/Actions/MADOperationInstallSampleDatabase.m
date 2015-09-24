//
//  MADOperationInstallSampleDatabase.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationInstallSampleDatabase.h"
#import <MADFoundation/UIApplication+MADAppDelegate.h>
#import <MADFoundation/NSFileManager+Common.h>

NSString * const MADUpgradeInstalledSamples                         = @"MADUpgradeInstalledSamples";
NSString * const MADUpgradeInstalledSamplesLondon                   = @"MADUpgradeInstalledSamplesLondon";
NSString * const MADUpgradeInstalledSamplesMusic                    = @"MADUpgradeInstalledSamplesMusic";
NSString * const MADUpgradeInstalledChinook                         = @"MADUpgradeInstalledChinook";

NSString * const MTSampleDatabaseChinook            = @"chinook";
NSString * const MTDocumentExtentionSqlite3         = @"sqlite3";

@implementation MADOperationInstallSampleDatabase

- (void)main {
    BOOL installed = [[NSUserDefaults standardUserDefaults] boolForKey:MADUpgradeInstalledChinook];
    if (installed == NO) {
        
        NSURL *fileUrl = [MADOperationInstallSampleDatabase applicationBundleSampleDatabaseChinook];
        NSURL *chinookAppSupportUrl = [MADOperationInstallSampleDatabase applicationSupportSampleDatabaseChinook];
        
        if (chinookAppSupportUrl != nil) {
            NSError *error = nil;
            [[NSFileManager defaultManager] copyItemAtURL:fileUrl toURL:chinookAppSupportUrl error:&error];
            installed = [[NSFileManager defaultManager] fileExistsAtPath:[chinookAppSupportUrl path]];
            if (installed) {
                NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
                [standardUserDefaults setBool:YES forKey:MADUpgradeInstalledChinook];
                [standardUserDefaults synchronize];
            }
        }
        
    }
}

+ (NSURL *)applicationBundleSampleDatabaseChinook {
    return [[NSBundle mainBundle] URLForResource: MTSampleDatabaseChinook
                                   withExtension: MTDocumentExtentionSqlite3];
}


+ (NSURL *)applicationSupportSampleDatabaseChinook {
    MADAppDelegate delegate = [UIApplication AppDelegate];
    NSURL *appSupportDirectory = [[NSFileManager defaultManager] localApplicationSupportDirectoryForGroupIdentifier:[delegate groupIdentifier]];
    NSString *filename = [NSString stringWithFormat:@"%@.%@", MTSampleDatabaseChinook, MTDocumentExtentionSqlite3];
    return [appSupportDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}

@end
