//
//  MADInstallOperationSampleDatabase.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADInstallOperationSampleDatabase.h"
#import <MAD/MADConstants.h>
#import <MADFileManager/MADFileUtilities.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSUserDefaults.h>

NSString * const MADUpgradeInstalledSamples                         = @"MADUpgradeInstalledSamples";
NSString * const MADUpgradeInstalledSamplesLondon                   = @"MADUpgradeInstalledSamplesLondon";
NSString * const MADUpgradeInstalledSamplesMusic                    = @"MADUpgradeInstalledSamplesMusic";
NSString * const MADUpgradeInstalledChinook                         = @"MADUpgradeInstalledChinook";

NSString * const MTSampleDatabaseChinook                            = @"chinook";
NSString * const MTDocumentExtentionSqlite3                         = @"sqlite3";

@implementation MADInstallOperationSampleDatabase

- (void)main {
    BOOL installed = [[NSUserDefaults standardUserDefaults] boolForKey:MADUpgradeInstalledChinook];
    if (installed == NO) {
        
        NSURL *fileUrl = [MADInstallOperationSampleDatabase applicationBundleSampleDatabaseChinook];
        NSURL *chinookAppSupportUrl = [MADInstallOperationSampleDatabase applicationSupportSampleDatabaseChinook];
        
        if (chinookAppSupportUrl != nil) {
            NSError *error = nil;
            [[NSFileManager defaultManager] copyItemAtURL:fileUrl toURL:chinookAppSupportUrl error:&error];
            installed = [[NSFileManager defaultManager] fileExistsAtPath:chinookAppSupportUrl.path];
            if (installed) {
                NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
                [standardUserDefaults setBool:YES forKey:MADUpgradeInstalledChinook];
                [standardUserDefaults synchronize];
            }
        }
    }
}

+ (NSURL *)applicationBundleSampleDatabaseChinook {
    return [[NSBundle mainBundle] URLForResource: MTSampleDatabaseChinook withExtension: MTDocumentExtentionSqlite3];
}

+ (NSURL *)applicationSupportSampleDatabaseChinook {
    NSURL *appSupportDirectory = [MADFileUtilities localApplicationSupportDirectoryForGroupIdentifier:MADIdentifierGroup];
    NSString *filename = [NSString stringWithFormat:@"%@.%@", MTSampleDatabaseChinook, MTDocumentExtentionSqlite3];
    return [appSupportDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}

@end
