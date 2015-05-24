//
//  MADUpgradeManager.m
//  MAD
//
//  Created by Michael Thomason on 9/12/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADUpgradeManager.h"
#import "MADConstants.h"
#import "MACloudManager.h"
#import "MTApplicationInstance.h"
#import "NSFileManager+Common.h"

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

const NSInteger currentMajorVersion = 8;

@implementation MADUpgradeManager

- (void)performUpgradeIfRequired:(void(^)(BOOL success, NSError *error, BOOL upgradePerformed))completion {
    BOOL upgradeRequired = NO;
    BOOL upgradeVersion1 = NO;
    BOOL upgradeVersion7 = NO;
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
        
        if (lastVersionRun.integerValue <= 1) {
            upgradeRequired = YES;
            upgradeVersion1 = YES;
        } else if (lastVersionRun.integerValue <= 7) {
            upgradeRequired = YES;
            upgradeVersion7 = YES;
        }
    }
    
    //upgradeRequired = YES;
    //upgradeVersion7 = YES;
    
    NSNumber *majorVersion = @(currentMajorVersion);
    [standardUserDefault setObject: majorVersion
                            forKey: MADUpgradeLastVersionRun];

    
    if (upgradeVersion7 && upgradeRequired) {
        [self migrateDocumentToGroupFolder];
    }
    
    
    if (installChinook || installSamples) {
        completion (YES, nil, YES);
    } else {
        completion (YES, nil, NO);
    }
    
    NSAssert(chinookInstalling == NO, @"%s", __PRETTY_FUNCTION__);

}

/*
 *  Upgrading 7 -> 8
 *      Move documents to group folder.
 */
- (void)migrateDocumentToGroupFolder {
    NSArray *documents = [[NSFileManager defaultManager] contentOfLocalDocumentsDirectoryWithExtention:MADFileExtentionMobleApplicationDocument];
    if (documents.count > 0) {
        
        NSURL *documentsDirectoryForAppGroup = [[NSFileManager defaultManager] localDocumentsDirectoryForGroupIdentifier:MADIdentifierGroup];
        //[defaultManager l]
        BOOL success = NO;
        NSError *error = nil;
        NSURL *destination;
        for (NSURL *document in documents) {
            destination = [documentsDirectoryForAppGroup URLByAppendingPathComponent:document.lastPathComponent];
            success = [[NSFileManager defaultManager] moveItemAtURL:document
                                                              toURL:destination
                                                              error:&error];
            if (success == NO || error != nil) {    // Try again, but don't try too hard... app not yet in wide use
                success = [[NSFileManager defaultManager] moveItemAtURL:document
                                                                  toURL:destination
                                                                  error:&error];
            }
        }
    }
}

+ (void)installSampleDatabase:(NSError **)error {
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

+ (void)installSamplesDocuments:(NSError **)error {
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
            NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
            [standardUserDefaults setObject:@YES forKey:MADUpgradeInstalledSamples];
            [standardUserDefaults synchronize];
        }
    }
}

+ (NSURL *)applicationSupportSampleDatabaseChinook {
    NSURL *appSupportDirectory = [[NSFileManager defaultManager] localApplicationSupportDirectoryForGroupIdentifier:MADIdentifierGroup];
    NSString *filename = [NSString stringWithFormat:@"%@.%@", MTSampleDatabaseChinook, MTDocumentExtentionSqlite3];
    return [appSupportDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}

/*
 * Location of the sample database inside the application bundle.
 */

+ (NSURL *)applicationBundleSampleDatabaseChinook {
    return [[NSBundle mainBundle] URLForResource:MTSampleDatabaseChinook
                                   withExtension:MTDocumentExtentionSqlite3];
}

@end
