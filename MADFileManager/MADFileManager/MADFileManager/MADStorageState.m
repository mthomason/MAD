//
//  MADStorageState.m
//  MADFileManager
//
//  Created by Michael Thomason on 9/12/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADStorageState.h"

@implementation MADStorageState

+ (instancetype)newStorageStateWithStorageOption:(MADAppStorage)storageOption
                      hasUbiquityIdentityChanged:(BOOL)hasUbiquityIdentityChanged
                         isCloudReadilyAvailable:(BOOL)isCloudReadilyAvailable {
    
    MADStorageState *storageState = [[MADStorageState alloc] init];
    storageState.storageOption = storageOption;
    storageState.accountDidChange = hasUbiquityIdentityChanged;
    storageState.cloudAvailable = isCloudReadilyAvailable;
    return storageState;
}

@end
