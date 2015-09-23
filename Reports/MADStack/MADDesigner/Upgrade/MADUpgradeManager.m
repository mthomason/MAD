//
//  MADUpgradeManager.m
//  MAD
//
//  Created by Michael Thomason on 9/12/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADUpgradeManager.h"
#import "MADAppConfiguration.h"
#import <MADFoundation/MADApplicationProtocol.h>

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
    
    NSURL *chinookUrl = [MADAppConfiguration applicationSupportSampleDatabaseChinook];
    BOOL isDirectory;
    BOOL gotChinook = [[NSFileManager defaultManager] fileExistsAtPath:chinookUrl.path isDirectory:&isDirectory];
    if (gotChinook == NO) {
        installChinook = YES;
    } else {
        installChinook = NO;
    }
    
    if ([[MADAppConfiguration mainInstance] isMadDesigner]) {
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

/*
 *  Upgrading 7 -> 8
 *      Move documents to group folder.
 */
- (void)migrateDocumentToGroupFolder {
    NSError *error = nil;
    [MADUpgradeManager installSampleDatabase:&error];
    id <UIApplicationDelegate, MADApplicationProtocol> appDelegate = (id <UIApplicationDelegate, MADApplicationProtocol>)[UIApplication sharedApplication].delegate;
    [MADFileUtilities copyInitialFiles:MADFileExtentionMobleApplicationDocument groupId:[appDelegate groupIdentifier]];
}

+ (BOOL)installSampleDatabase:(NSError **)error {
    BOOL installed = [[NSUserDefaults standardUserDefaults] boolForKey:MADUpgradeInstalledChinook];
    if (installed == NO) {

        NSURL *fileUrl = [MADAppConfiguration applicationBundleSampleDatabaseChinook];
        NSURL *chinookAppSupportUrl = [MADAppConfiguration applicationSupportSampleDatabaseChinook];
        NSFileManager *defaultManager = [NSFileManager defaultManager];
        
        if (chinookAppSupportUrl != nil) {
            [defaultManager copyItemAtURL:fileUrl toURL:chinookAppSupportUrl error:error];
            installed = [defaultManager fileExistsAtPath:[chinookAppSupportUrl path]];
            if (installed) {
                NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
                [standardUserDefaults setBool:YES forKey:MADUpgradeInstalledChinook];
                [standardUserDefaults synchronize];
            }
        }

    }
    return installed;
}

+ (BOOL)installSamplesDocuments:(NSError **)error {
    /*
    BOOL installed = [[NSUserDefaults standardUserDefaults] boolForKey:MADUpgradeInstalledSamples];
    if (installed == NO) {

        NSBundle *mainBundle = [NSBundle mainBundle];
        NSURL *sampleUrl1 = [mainBundle URLForResource: MADIdentifierFileLondon
                                         withExtension: MADFileExtentionMobleApplicationDocument];
        NSURL *sampleUrl2 = [mainBundle URLForResource: MADIdentifierFileMusic
                                         withExtension: MADFileExtentionMobleApplicationDocument];
        
        NSFileManager *defaultManager = [NSFileManager defaultManager];
        NSURL *documentDirectory = [defaultManager localDocumentsDirectoryForGroupIdentifier:MADIdentifierGroup];
        
        if (documentDirectory) {
            NSURL *londonUrl = [documentDirectory URLByAppendingPathComponent: MADIdentifierFileLondon
                                                                  isDirectory: NO];
            londonUrl = [londonUrl URLByAppendingPathExtension:MADFileExtentionMobleApplicationDocument];
            NSURL *musicUrl = [documentDirectory URLByAppendingPathComponent: MADIdentifierFileMusic
                                                                 isDirectory: NO];
            musicUrl = [musicUrl URLByAppendingPathExtension:MADFileExtentionMobleApplicationDocument];
            error = nil;

            [defaultManager copyItemAtURL:sampleUrl1 toURL:londonUrl error:error];
            if (error == nil) {
                [defaultManager copyItemAtURL:sampleUrl2 toURL:musicUrl error:error];
            }
            if (error == nil) {
                installed = YES;
                NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
                [standardUserDefaults setBool:YES forKey:MADUpgradeInstalledSamples];
                [standardUserDefaults synchronize];
            }
        }
    }
    return installed;*/
    return YES;
}

+ (void)installSamples {
    if ([[MADAppConfiguration mainInstance] sampleInstalled] == NO) {
        dispatch_queue_t queue = dispatch_queue_create(queueUpgrade, DISPATCH_QUEUE_SERIAL);
        dispatch_async(queue, ^{
            NSError *error = nil;
            BOOL installedDocs = [MADUpgradeManager installSamplesDocuments:&error];
            BOOL installedDB = [MADUpgradeManager installSampleDatabase:&error];
            if (installedDocs && installedDB) {
                [[MADAppConfiguration mainInstance] installedSample];
            }
        });
    }
}

@end
