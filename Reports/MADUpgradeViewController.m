//
//  MADUpgradeViewController.m
//  MAD
//
//  Created by Michael Thomason on 9/10/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MADUpgradeViewController.h"
#import "NSFileManager+Reports.h"
//#import "MADocument.h"
#import "MACloudManager.h"
#import "MTLog.h"
#import "NSFileManager+Common.h"
#import "MTDatabaseConnection.h"
#import "MTDatabaseSqlite3.h"
//#import "MAReportDocument.h"
#import "MTApplicationInstance.h"

#define MADUPGRADE_CREATE_SAMPLE FALSE       //Not for production use.

NSString * const MADUpgradeInstalledChinook = @"MADUpgradeInstalledChinook";
NSString * const MADUpgradeInstalledSamples = @"MADUpgradeInstalledSamples";
NSString * const MADUpgradeLastVersionRun = @"MADUpgradeLastVersionRun";

const NSInteger currentMajorVersion = 2;


@interface MADUpgradeViewController ()

@property (nonatomic, assign) BOOL upgradeRequired;

@property (nonatomic, assign) BOOL upgradeVersion1;
@property (nonatomic, assign) BOOL upgradeVersion2;

@property (nonatomic, assign) BOOL installChinook;
@property (nonatomic, assign) BOOL installSamples;

@end

@implementation MADUpgradeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BOOL upgradeRequired = NO;
    BOOL upgradeVersion1 = NO;
    BOOL upgradeVersion2 = NO;
    
    NSUserDefaults *standardUserDefault = [NSUserDefaults standardUserDefaults];
    NSNumber *lastVersionRun = [standardUserDefault objectForKey:MADUpgradeLastVersionRun];
    
    //For testing
    //lastVersionRun = @(1);
    
    NSURL *chinookUrl = [self chinookDbUrl];
    BOOL gotChinook = [[NSFileManager defaultManager] fileExistsAtPath:[chinookUrl path] isDirectory:NO];
    if (gotChinook == NO) {
        self.installChinook = YES;
    } else {
        self.installChinook = NO;
    }
    
    if ([MTApplicationInstance isMadDesigner]) {
        NSNumber *samplesInstalled = [standardUserDefault objectForKey:MADUpgradeInstalledSamples];
        if (samplesInstalled == nil) {
            self.installSamples = YES;
        } else {
            self.installSamples = NO;
        }
    } else {
        self.installSamples = NO;
    }
    
    if (lastVersionRun == nil) lastVersionRun = @(1);
    if ([lastVersionRun integerValue] < currentMajorVersion) {
        
        if ([lastVersionRun integerValue] == 1) {
            //Upgrade from version 1
            
            upgradeRequired = YES;
            upgradeVersion1 = YES;
            
        }
        
    }
    NSNumber *majorVersion = @(currentMajorVersion);
    [standardUserDefault setObject:majorVersion forKey:MADUpgradeLastVersionRun];
    
    if (upgradeRequired == NO && [self installChinook] == NO && [self installSamples] == NO) {
        [self performSegueWithIdentifier:@"MTSegueUpgradeUnneeded" sender:self];
    }
    
    [self setUpgradeRequired:upgradeRequired];
    [self setUpgradeVersion1:upgradeVersion1];
    [self setUpgradeVersion2:upgradeVersion2];
    
}

- (NSURL *)chinookDbUrl {
    NSURL *appSupportDirectory = [NSFileManager applicationSupportDirectory];
    return [appSupportDirectory URLByAppendingPathComponent:@"chinook.sqlite3" isDirectory:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSFileManager *defaultManager = [NSFileManager defaultManager];
    
    BOOL chinookInstalling = NO;
    
    if ([self installChinook]) {
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSURL *fileUrl = [mainBundle URLForResource:@"chinook" withExtension:@"sqlite3"];
        NSURL *appSupportDirectory = [NSFileManager applicationSupportDirectory];
        NSURL *chinookAppSupportUrl = nil;

        
        chinookAppSupportUrl = [appSupportDirectory URLByAppendingPathComponent:@"chinook.sqlite3" isDirectory:NO];
        
        if (chinookAppSupportUrl != nil) {
            NSError *error = nil;
            [defaultManager copyItemAtURL:fileUrl toURL:chinookAppSupportUrl error:&error];
            BOOL fileExist = [defaultManager fileExistsAtPath:[chinookAppSupportUrl path]];
            if (fileExist) {
                NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
                [standardUserDefaults setObject:@YES forKey:MADUpgradeInstalledChinook];
                [standardUserDefaults synchronize];
            } else {
                [defaultManager copyItemAtPath:[fileUrl path] toPath:[chinookAppSupportUrl path] error:&error]; //Try again?!?!
            }
        }
        
#if MADUPGRADE_CREATE_SAMPLE == TRUE
        chinookInstalling = YES;
        MTDatabaseConnection *dbDetails = [[MTDatabaseConnection alloc] init];
        [dbDetails setDatabaseTypeIdentifier:  [MTDatabaseSqlite3 identifier]];

        
        [dbDetails setDatabaseUrl:chinookAppSupportUrl];
        NSArray *possibleDocumentDirectoryUrls = [defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *documentDirectoryUrl = nil;
        NSURL *exampleFileUrl = nil;
        if ([possibleDocumentDirectoryUrls count] >= 1) {
            documentDirectoryUrl = [possibleDocumentDirectoryUrls objectAtIndex:0];
            exampleFileUrl = [documentDirectoryUrl URLByAppendingPathComponent:@"Chinook.mad" isDirectory:NO];
        }
        if (exampleFileUrl != nil) {
            
            __block MADUpgradeViewController *blockSelf = self;
            [MAReportDocument initalSaveUsingUrl:exampleFileUrl andConnection:dbDetails completion:^(BOOL success) {
                [blockSelf performSegueWithIdentifier:@"MTSegueUpgradeComplete" sender:blockSelf];
            }];
        }
        [dbDetails release];
#endif

    }
    
    if ([self installSamples]) {
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSURL *sampleUrl1 = [mainBundle URLForResource:@"London" withExtension:@"mad"];
        NSURL *sampleUrl2 = [mainBundle URLForResource:@"Music" withExtension:@"mad"];
        
        NSArray *possibleDocumentDirectoryUrls = [defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *documentDirectoryUrl = nil;

        if ([possibleDocumentDirectoryUrls count] >= 1) {
            documentDirectoryUrl = [possibleDocumentDirectoryUrls objectAtIndex:0];
            NSURL *londonUrl = [documentDirectoryUrl URLByAppendingPathComponent:@"London.mad" isDirectory:NO];
            NSURL *musicUrl = [documentDirectoryUrl URLByAppendingPathComponent:@"Music.mad" isDirectory:NO];
            NSError *error = nil;
            NSError *error2 = nil;
            [defaultManager copyItemAtURL:sampleUrl1 toURL:londonUrl error:&error];
            [defaultManager copyItemAtURL:sampleUrl2 toURL:musicUrl error:&error2];
            if (error == nil && error2 == nil) {
                NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
                [standardUserDefaults setObject:@YES forKey:MADUpgradeInstalledSamples];
                [standardUserDefaults synchronize];
            } else {
                NSString *londonPath = [londonUrl path];
                NSString *musicPath = [musicUrl path];
                BOOL fileOneExist = [defaultManager fileExistsAtPath:londonPath isDirectory:NO];
                BOOL fileTwoExist = [defaultManager fileExistsAtPath:musicPath isDirectory:NO];
                if (fileOneExist && fileTwoExist) {
                    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
                    [standardUserDefaults setObject:@YES forKey:MADUpgradeInstalledSamples];
                    [standardUserDefaults synchronize];
                }
            }
        }
    }
    
    if ([self upgradeRequired]) {
        if ([self upgradeVersion1] == YES) {
            
            //Wrap all modo files from the ~/Documents/Data folder, and save as
            //  mad files in the ~/Documents folder.
            NSArray *oldSchemaFiles = [[NSFileManager schemaFilesOld] retain];
            for (NSURL *urlToUpgrade in oldSchemaFiles) {
                [NSFileManager wrapFile:urlToUpgrade withExtention:MTDocumentExtentionMobleApplicationDocument overwrite:NO completion:^(BOOL success, NSURL *resultUrl) {
                    if (success) {
                        [MADocument deleteFromDisk:urlToUpgrade completion:^(BOOL success) {
                            
                            NSString *path = [[[MACloudManager sharedManager] documentsDataDirectoryURL] path];
                            NSError *error = nil;
                            NSArray *contentsOfDirectoryToDelete = [defaultManager contentsOfDirectoryAtPath:path error:&error];
                            if (error == nil) {
                                if ([contentsOfDirectoryToDelete count] == 0) {
                                    [defaultManager removeItemAtPath:path error:&error];
                                    if (error) {
                                        MTLog(@"%@", error);
                                    }
                                }
                            }
                            
                        }];
                    }
                }];
            }
            [oldSchemaFiles release];
            
        } else if ([self upgradeVersion2] == YES) {
            //For the future
        }
    }
    if (chinookInstalling == NO) {
        [self performSegueWithIdentifier:@"MTSegueUpgradeComplete" sender:self];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
