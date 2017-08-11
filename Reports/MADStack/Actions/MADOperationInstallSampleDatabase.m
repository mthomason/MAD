//
//  MADInstallOperationSampleDatabase.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationInstallSampleDatabase.h"

#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSBundle.h>

#import <MAD/MADConstants.h>
#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADAppDelegate.h>
#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/MADURL.h>

#import <os/log.h>

NSString * const MADUpgradeInstalledSamples         = @"MADUpgradeInstalledSamples";
NSString * const MADUpgradeInstalledChinook         = @"MADUpgradeInstalledChinook";

static NSString * const MTSampleDatabaseChinook            = @"chinook";
static NSString * const MTDocumentExtentionSqlite3         = @"sqlite3";

@implementation MADOperationInstallSampleDatabase

- (void)dealloc { }


- (BOOL)isAsynchronous { return YES; }

- (void)execute {

    NSURL *fileURL, *databaseURL;
    NSError *error = nil;

    if (self.cancelled) goto FINISH;

    BOOL installed = [[NSUserDefaults standardUserDefaults] boolForKey:MADUpgradeInstalledChinook];
    if (installed) goto FINISH;

    
    fileURL = [MADOperationInstallSampleDatabase newApplicationBundleSampleDatabaseChinook];
    databaseURL = [MADOperationInstallSampleDatabase newApplicationSupportSampleDatabaseChinook];
    
    if (databaseURL == nil) goto FINISH;
    
    installed = [[NSFileManager defaultManager] copyItemAtURL: fileURL
                                                        toURL: databaseURL
                                                        error: &error];
    
    if (installed) {
        NSString *filepath = databaseURL.path;
        if ([[NSFileManager defaultManager] fileExistsAtPath:filepath]) {
            [[NSUserDefaults standardUserDefaults] setBool: YES
                                                    forKey: MADUpgradeInstalledChinook];
            [[NSUserDefaults standardUserDefaults] synchronize];
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
    id appSupportDirectory = [MADURL newURLApplicationSupportFile: MTSampleDatabaseChinook
                                                        extension: MTDocumentExtentionSqlite3];
    return appSupportDirectory;
}

@end
