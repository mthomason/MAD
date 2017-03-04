//
//  MADCloudManager.h
//  MADFileManager
//
//  Created by Michael Thomason on 5/29/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADCloudManager_h
#define MAD_MADCloudManager_h

#import <Foundation/NSObject.h>
#import "MADAppStorageOption.h"

@protocol MADCloudManagerDelegate;

@interface MADCloudManager : NSObject

    @property (nonatomic, weak) id <MADCloudManagerDelegate> delegate;
    @property (nonatomic, readonly) MADAppStorage userPreference;
    @property (nonatomic, readonly) NSURL *ubiquityContainer;

@end

#endif
