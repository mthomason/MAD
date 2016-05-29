//
//  MADCloudManager.h
//  MADFileManager
//
//  Created by Michael Thomason on 5/29/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADCloudManager_h
#define MAD_MADCloudManager_h

#import <Foundation/NSObject.h>

typedef NS_ENUM(short, MADCloudPreference) {
    MADCloudPreferenceCloud,
    MADCloudPreferenceLocal,
    MADCloudPreferenceCloudSignedOut,
    MADCloudPreferenceUnknown,
};

@interface MADCloudManager : NSObject

    @property (nonatomic, readonly) MADCloudPreference userPreference;

@end

#endif
