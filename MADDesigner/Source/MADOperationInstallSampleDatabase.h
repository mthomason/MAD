//
//  MADInstallOperationSampleDatabase.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADInstallOperationSampleDatabase_h
#define Reports_MADInstallOperationSampleDatabase_h

#import <MADFoundation/MADOperation.h>

extern NSString * const MADUpgradeInstalledSamples;
extern NSString * const MADUpgradeInstalledChinook;

@interface MADOperationInstallSampleDatabase : MADOperation

+ (NSURL *)newApplicationSupportSampleDatabaseChinook;

@end

#endif
