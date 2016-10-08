//
//  MADStorageState.m
//  MADFileManager
//
//  Created by Michael Thomason on 9/12/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADStorageState.h"
#import <Foundation/NSString.h>

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

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    NSString *classname = NSStringFromClass([self class]);
    id uppercaseClassname = [classname uppercaseString];
    [debug appendFormat:@"--%@--\n", uppercaseClassname];
    return debug;
}

@end
