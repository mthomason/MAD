//
//  MADOperationInstallSampleDatabase.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationInstallSampleDatabase.h"
#import "MADAppConfiguration.h"

@implementation MADOperationInstallSampleDatabase

- (void)main {
    BOOL installed = [[NSUserDefaults standardUserDefaults] boolForKey:MADUpgradeInstalledChinook];
    if (installed == NO) {
        
        NSURL *fileUrl = [MADAppConfiguration applicationBundleSampleDatabaseChinook];
        NSURL *chinookAppSupportUrl = [MADAppConfiguration applicationSupportSampleDatabaseChinook];
        
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

@end
