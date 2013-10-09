//
//  MADUpgradeViewController.m
//  MAD
//
//  Created by Michael Thomason on 9/10/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MADUpgradeViewController.h"
#import "NSFileManager+Reports.h"
#import "MADocument.h"
#import "MACloudManager.h"
#import "MTLog.h"
#import "NSFileManager+Common.h"

@interface MADUpgradeViewController ()

@property (nonatomic, assign) BOOL upgradeRequired;

@property (nonatomic, assign) BOOL upgradeVersion1;
@property (nonatomic, assign) BOOL upgradeVersion2;

@end

@implementation MADUpgradeViewController

- (void)dealloc {
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BOOL upgradeRequired = NO;
    BOOL upgradeVersion1 = NO;
    BOOL upgradeVersion2 = NO;
    
    NSString *lastVersionRunKey = @"lastVersionRun";
    NSUserDefaults *standardUserDefault = [NSUserDefaults standardUserDefaults];
    NSInteger currentMajorVersion = 2;
    NSNumber *lastVersionRun = [standardUserDefault objectForKey:lastVersionRunKey];
    
    //For testing
    //lastVersionRun = @(1);
    
    if (lastVersionRun == nil) lastVersionRun = @(1);
    if ([lastVersionRun integerValue] < currentMajorVersion) {
        
        if ([lastVersionRun integerValue] == 1) {
            //Upgrade from version 1
            
            upgradeRequired = YES;
            upgradeVersion1 = YES;
            
        }
        
    }
    [standardUserDefault setObject:@(currentMajorVersion) forKey:lastVersionRunKey];
    
    if (upgradeRequired == NO) {
        [self performSegueWithIdentifier:@"MTSegueUpgradeUnneeded" sender:self];
    }
    
    [self setUpgradeRequired:upgradeRequired];
    [self setUpgradeVersion1:upgradeVersion1];
    [self setUpgradeVersion2:upgradeVersion2];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if ([self upgradeRequired]) {
        if ([self upgradeVersion1] == YES) {
            NSFileManager *defaultManager = [NSFileManager defaultManager];
            
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
    [self performSegueWithIdentifier:@"MTSegueUpgradeComplete" sender:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
