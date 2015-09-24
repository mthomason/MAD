//
//  MADOperationInstallSampleDatabase.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const MADUpgradeInstalledSamples;
extern NSString * const MADUpgradeInstalledChinook;
extern NSString * const MADUpgradeInstalledSamplesLondon;
extern NSString * const MADUpgradeInstalledSamplesMusic;

@interface MADOperationInstallSampleDatabase : NSOperation

+ (NSURL *)applicationBundleSampleDatabaseChinook;
+ (NSURL *)applicationSupportSampleDatabaseChinook;

@end
