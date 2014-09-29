//
//  MADUpgradeManager.m
//  MAD
//
//  Created by Michael Thomason on 9/12/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADUpgradeManager.h"
#import "NSFileManager+Common.h"
#import "MACloudManager.h"
#import "MTApplicationInstance.h"

#define MADUPGRADE_CREATE_SAMPLE FALSE       //Not for production use.

NSString * const MADUpgradeInstalledChinook         = @"MADUpgradeInstalledChinook";
NSString * const MADUpgradeInstalledSamples         = @"MADUpgradeInstalledSamples";
NSString * const MADUpgradeLastVersionRun           = @"MADUpgradeLastVersionRun";
NSString * const MADIdentifierSegueUpgradeComplete  = @"MTSegueUpgradeComplete";
NSString * const MADIdentifierSegueUpgradeUnneeded  = @"MTSegueUpgradeUnneeded";

NSString * const MADIdentifierFileLondon            = @"London";
NSString * const MADIdentifierFileMusic             = @"Music";
NSString * const MTSampleDatabaseChinook            = @"chinook";
NSString * const MTDocumentExtentionSqlite3         = @"sqlite3";

const NSInteger currentMajorVersion = 2;

@implementation MADUpgradeManager

- (void)performUpgradeIfRequired:(void(^)(BOOL success, NSError *error, BOOL upgradePerformed))completion {
    BOOL upgradeRequired = NO;
    BOOL upgradeVersion1 = NO;
    BOOL installChinook = NO;
    BOOL installSamples = NO;
    
    NSUserDefaults *standardUserDefault = [NSUserDefaults standardUserDefaults];
    NSNumber *lastVersionRun = [standardUserDefault objectForKey:MADUpgradeLastVersionRun];
    
    NSURL *chinookUrl = [MADUpgradeManager applicationSupportSampleDatabaseChinook];
    BOOL isDirectory;
    BOOL gotChinook = [[NSFileManager defaultManager] fileExistsAtPath:chinookUrl.path isDirectory:&isDirectory];
    if (gotChinook == NO) {
        installChinook = YES;
    } else {
        installChinook = NO;
    }
    
    if ([MTApplicationInstance isMadDesigner]) {
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
        
        if (lastVersionRun.integerValue == 1) {
            upgradeRequired = YES;
            upgradeVersion1 = YES;
        }
        
    }
    NSNumber *majorVersion = @(currentMajorVersion);
    [standardUserDefault setObject:majorVersion forKey:MADUpgradeLastVersionRun];
    upgradeRequired = upgradeRequired;

    
    if (installChinook || installSamples) {
        
        __weak MADUpgradeManager *weakself = self;
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_async(queue, ^{
            NSError *error = nil;
            if (installChinook) {
                [weakself installSampleDatabase:&error];
            }
            if (installSamples) {
                [self installSamplesDocuments:&error];
            }
            BOOL upgradePerformed = installSamples || installChinook;
            dispatch_sync(dispatch_get_main_queue(), ^{
                completion (error == nil, error, upgradePerformed);
            });
        });
    } else {
        completion (YES, nil, NO);
    }
    
    NSAssert(chinookInstalling == NO, @"%s", __PRETTY_FUNCTION__);
}

- (void)installSampleDatabase:(NSError **)error {
    NSURL *fileUrl = [MADUpgradeManager applicationBundleSampleDatabaseChinook];
    NSURL *chinookAppSupportUrl = [MADUpgradeManager applicationSupportSampleDatabaseChinook];
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    
    if (chinookAppSupportUrl != nil) {
        [defaultManager copyItemAtURL:fileUrl toURL:chinookAppSupportUrl error:error];
        BOOL fileExist = [defaultManager fileExistsAtPath:[chinookAppSupportUrl path]];
        if (fileExist) {
            NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
            [standardUserDefaults setObject:@YES forKey:MADUpgradeInstalledChinook];
            [standardUserDefaults synchronize];
        }
    }
}

- (void)installSamplesDocuments:(NSError **)error {
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *sampleUrl1 = [mainBundle URLForResource: MADIdentifierFileLondon
                                     withExtension: MTDocumentExtentionMobleApplicationDocument];
    NSURL *sampleUrl2 = [mainBundle URLForResource: MADIdentifierFileMusic
                                     withExtension: MTDocumentExtentionMobleApplicationDocument];
    
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSArray *possibleDocumentDirectoryUrls = [defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentDirectoryUrl = nil;
    
    if ([possibleDocumentDirectoryUrls count] >= 1) {
        documentDirectoryUrl = possibleDocumentDirectoryUrls[0];
        NSURL *londonUrl = [documentDirectoryUrl URLByAppendingPathComponent: MADIdentifierFileLondon
                                                                 isDirectory: NO];
        londonUrl = [londonUrl URLByAppendingPathExtension:MTDocumentExtentionMobleApplicationDocument];
        NSURL *musicUrl = [documentDirectoryUrl URLByAppendingPathComponent: MADIdentifierFileMusic
                                                                isDirectory: NO];
        musicUrl = [musicUrl URLByAppendingPathExtension:MTDocumentExtentionMobleApplicationDocument];
        error = nil;
        [defaultManager copyItemAtURL:sampleUrl1 toURL:londonUrl error:error];
        if (error == nil) {
            [defaultManager copyItemAtURL:sampleUrl2 toURL:musicUrl error:error];
        }
        if (error == nil) {
            NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
            [standardUserDefaults setObject:@YES forKey:MADUpgradeInstalledSamples];
            [standardUserDefaults synchronize];
        }
    }
}

+ (NSURL *)applicationSupportSampleDatabaseChinook {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportDirectory = [fileManager localApplicationSupportDirectory];
    NSString *filename = [NSString stringWithFormat:@"%@.%@", MTSampleDatabaseChinook, MTDocumentExtentionSqlite3];
    return [appSupportDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}

+ (NSURL *)applicationBundleSampleDatabaseChinook {
    NSBundle *mainBundle = [NSBundle mainBundle];
    return [mainBundle URLForResource:MTSampleDatabaseChinook withExtension:MTDocumentExtentionSqlite3];
}

@end
