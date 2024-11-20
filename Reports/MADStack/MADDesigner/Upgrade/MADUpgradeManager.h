//
//  MADUpgradeManager.h
//  MAD
//
//  Created by Michael Thomason on 9/12/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

// This is currently unused, but it should be used to update a persons files if the
//		file format changes.

#ifndef MAD_MADUpgradeManager_h
#define MAD_MADUpgradeManager_h

#import <Foundation/NSObject.h>

@interface MADUpgradeManager : NSObject

	- (void)performUpgradeIfRequired:(void(^)(BOOL success, NSError *error,
											  BOOL upgradePerformed))completion;

@end

#endif
