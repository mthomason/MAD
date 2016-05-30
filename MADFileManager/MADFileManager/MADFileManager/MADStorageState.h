//
//  MADStorageState.h
//  MADFileManager
//
//  Created by Michael Thomason on 9/12/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADFileManager_MADStorageState_h
#define MADFileManager_MADStorageState_h

#import <Foundation/NSObject.h>
#import <MADFileManager/MADAppStorageOption.h>

@interface MADStorageState : NSObject

    @property (nonatomic, assign) MADAppStorage storageOption;
    @property (nonatomic, assign) BOOL accountDidChange;
    @property (nonatomic, assign) BOOL cloudAvailable;

    + (instancetype)newStorageStateWithStorageOption:(MADAppStorage)storageOption
                          hasUbiquityIdentityChanged:(BOOL)hasUbiquityIdentityChanged
                             isCloudReadilyAvailable:(BOOL)isCloudReadilyAvailable;


@end

#endif
