//
//  MADSettingsManager.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/17/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MADPreference.h"

@interface MADPreferencesManager : NSObject

+ (instancetype)sharedManager;

- (void)addPreference:(MADPreference *)preference;

@end
