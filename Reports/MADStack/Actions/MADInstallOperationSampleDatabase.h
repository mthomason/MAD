//
//  MADInstallOperationSampleDatabase.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADInstallOperationSampleDatabase_h
#define Reports_MADInstallOperationSampleDatabase_h

#import "MADOperation.h"

extern NSString * const MADUpgradeInstalledSamples;
extern NSString * const MADUpgradeInstalledChinook;
extern NSString * const MADUpgradeInstalledSamplesLondon;
extern NSString * const MADUpgradeInstalledSamplesMusic;

@interface MADInstallOperationSampleDatabase : MADOperation

    + (NSURL *)newApplicationBundleSampleDatabaseChinook;
    + (NSURL *)newApplicationSupportSampleDatabaseChinook;

@end

#endif
