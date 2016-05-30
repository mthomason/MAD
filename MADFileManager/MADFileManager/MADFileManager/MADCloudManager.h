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
#import "MADAppStorageOption.h"

@protocol MADCloudManagerDelegate <NSObject>

    - (void)promptUserForCloudPreference:(void (^)(MADAppStorage preference))result;

@end

@interface MADCloudManager : NSObject

    @property (nonatomic, weak) id <MADCloudManagerDelegate> delegate;
    @property (nonatomic, readonly) MADAppStorage userPreference;
    @property (nonatomic, readonly) NSURL *ubiquityContainer;

@end

#endif
