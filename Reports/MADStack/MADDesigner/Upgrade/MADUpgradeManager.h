//
//  MADUpgradeManager.h
//  MAD
//
//  Created by Michael Thomason on 9/12/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADUpgradeManager_h
#define MAD_MADUpgradeManager_h

#import <Foundation/Foundation.h>
#import <MADFileManager/MADFileManager.h>
#import <MAD/MADConstants.h>

@interface MADUpgradeManager : NSObject

- (void)performUpgradeIfRequired:(void(^)(BOOL success, NSError *error, BOOL upgradePerformed))completion;

@end

#endif
