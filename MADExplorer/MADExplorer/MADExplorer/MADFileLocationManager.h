//
//  MADFileLocationManager.h
//  MAD Explorer
//
//  Created by Michael Thomason on 9/12/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADExplorer_MADFileLocationManager_h
#define MADExplorer_MADFileLocationManager_h

#import <Foundation/NSObject.h>

@protocol MADFileLocationManagerDelegate;

@class MADFilesController;

@interface MADFileLocationManager : NSObject

@property (nonatomic, weak) id <MADFileLocationManagerDelegate> delegate;
@property (nonatomic, strong, readonly) MADFilesController *filesController;

- (instancetype)initWithUbiquityID:(NSString *)ubiquityID andGroupID:(NSString *)groupID;
- (void)getUserCloudPrefs;

@end

#endif
