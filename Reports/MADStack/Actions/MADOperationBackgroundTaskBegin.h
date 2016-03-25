//
//  MADOperationBackgroundTaskBegin.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperationBackgroundTaskBegin_h
#define MAD_Designer_MADOperationBackgroundTaskBegin_h

#import "MADOperation.h"
#import <UIKit/UIApplication.h>

@protocol MADBackgroundTaskProtocol <NSObject>

    - (UIBackgroundTaskIdentifier)backgroundTaskIdentifier;

@end

@interface MADOperationBackgroundTaskBegin : MADOperation

@end

#endif
