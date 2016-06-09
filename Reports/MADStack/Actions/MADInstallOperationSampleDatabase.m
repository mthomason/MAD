//
//  MADInstallOperationSampleDatabase.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADInstallOperationSampleDatabase.h"
#import <MAD/MADConstants.h>
#import <MADFoundation/NSURL+CommonURLs.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSUserDefaults.h>

NSString * const MADUpgradeInstalledSamples         = @"MADUpgradeInstalledSamples";
NSString * const MADUpgradeInstalledChinook         = @"MADUpgradeInstalledChinook";

NSString * const MTSampleDatabaseChinook            = @"chinook";
NSString * const MTDocumentExtentionSqlite3         = @"sqlite3";

@implementation MADInstallOperationSampleDatabase

- (void)dealloc {
    NSLog(@"dealloc MADInstallOperationSampleDatabase");
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {

    NSURL *fileURL, *databaseURL;

    if (self.cancelled) goto FINISH;

    BOOL installed = [[NSUserDefaults standardUserDefaults] boolForKey:MADUpgradeInstalledChinook];
    if (installed) goto FINISH;

    
    fileURL = [MADInstallOperationSampleDatabase newApplicationBundleSampleDatabaseChinook];
    databaseURL = [MADInstallOperationSampleDatabase newApplicationSupportSampleDatabaseChinook];
    
    if (databaseURL == nil) goto FINISH;
    
    [MADInstallOperationSampleDatabase copyItemAtURL:fileURL toURL:databaseURL];

    FINISH:;
    [self finish];

}

+ (BOOL)copyItemAtURL:(NSURL *)fromURL toURL:(NSURL *)toURL {
    BOOL installed;
    NSError *error = nil;
    [[NSFileManager defaultManager] copyItemAtURL: fromURL
                                            toURL: toURL
                                            error: &error];
    NSString *path = toURL.path;
    installed = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (installed) {
        [[NSUserDefaults standardUserDefaults] setBool: YES
                                                forKey: MADUpgradeInstalledChinook];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return installed;
}

+ (NSURL *)newApplicationBundleSampleDatabaseChinook {
    return [[NSBundle mainBundle] URLForResource: MTSampleDatabaseChinook
                                   withExtension: MTDocumentExtentionSqlite3];
}

+ (NSURL *)newApplicationSupportSampleDatabaseChinook {
    NSURL *appSupportDirectory =
        [NSURL newURLLocalApplicationSupportDirectoryForGroupID: MADIdentifierGroup];
    NSString *filename = [[NSString alloc] initWithFormat: @"%@.%@",
                                                MTSampleDatabaseChinook,
                                                MTDocumentExtentionSqlite3];
    return [appSupportDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}

@end
