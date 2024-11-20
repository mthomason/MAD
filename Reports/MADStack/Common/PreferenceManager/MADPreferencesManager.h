//
//  MADSettingsManager.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/17/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADPreferencesManager_h
#define MAD_Designer_MADPreferencesManager_h

#import <Foundation/NSObject.h>
#import "MADPreference.h"

@interface MADPreferencesManager : NSObject

    + (instancetype)sharedManager;
    - (void)addPreference:(MADPreference *)preference;

@end

@interface MADPreferencesManager (Storage)

- (MADPreference *)storageOption;

@end

#endif
