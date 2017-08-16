//
//  MADOperationBackgroundTaskBegin.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperationBackgroundTaskBegin_h
#define MAD_Designer_MADOperationBackgroundTaskBegin_h

#import <UIKit/UIApplication.h>
#import <MADFoundation/MADOperation.h>

@protocol MADOperationBackgroundTaskProtocol <NSObject>
    - (UIBackgroundTaskIdentifier)backgroundTaskIdentifier;
@end

@interface MADOperationBackgroundTaskBegin : MADOperation

@end

#endif
