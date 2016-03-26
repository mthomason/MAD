//
//  MADNotificationProgress.h
//  MAD
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADNotificationProgress_h
#define Reports_MADNotificationProgress_h

#import <Foundation/NSObject.h>

extern NSString * const MADNotificationProgressIdentifier;

@class MADProgress;

@interface MADNotificationProgress : NSObject

    + (MADNotificationProgress *)sharedObject;
    - (void)updateProgressWithMessage:(NSString *)message progress:(float)progress;
    - (void)updateProgress:(MADProgress *)progress;

@end

#endif
