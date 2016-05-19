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

- (void)dealloc {
    NSLog(@"dealloc MADInstallOperationSampleDatabase");
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {

    if (self.cancelled) {
        goto FINISH;
    }

    BOOL installed = [[NSUserDefaults standardUserDefaults] boolForKey:MADUpgradeInstalledChinook];
    if (installed == NO) {

        [self finishIfCancelled];
        
        NSURL *fileUrl = [MADInstallOperationSampleDatabase newApplicationBundleSampleDatabaseChinook];
        NSURL *chinookAppSupportUrl = [MADInstallOperationSampleDatabase newApplicationSupportSampleDatabaseChinook];
        
        if (chinookAppSupportUrl != nil) {
            NSError *error = nil;
            [[NSFileManager defaultManager] copyItemAtURL: fileUrl toURL: chinookAppSupportUrl
                                                    error: &error];
            NSString *path = chinookAppSupportUrl.path;
            installed = [[NSFileManager defaultManager] fileExistsAtPath:path];
            if (installed) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:MADUpgradeInstalledChinook];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
    }

    FINISH:;
    [self finish];

}

+ (NSURL *)newApplicationBundleSampleDatabaseChinook {
    return [[NSBundle mainBundle] URLForResource: MTSampleDatabaseChinook
                                   withExtension: MTDocumentExtentionSqlite3];
}

+ (NSURL *)newApplicationSupportSampleDatabaseChinook {
    NSURL *appSupportDirectory =
        [MADFileUtilities localApplicationSupportDirectoryForGroupIdentifier: MADIdentifierGroup];
    NSString *filename = [[NSString alloc] initWithFormat: @"%@.%@",
                                                MTSampleDatabaseChinook,
                                                MTDocumentExtentionSqlite3];
    return [appSupportDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}

@end
