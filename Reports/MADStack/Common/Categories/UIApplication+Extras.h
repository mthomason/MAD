//
//  UIApplication+Extras.h
//  MAD
//
//  Created by Michael Thomason on 9/20/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UIApplication_Extras_h
#define Reports_UIApplication_Extras_h

#import <UIKit/UIApplication.h>

@interface UIApplication (Extras)

    + (NSString *)version;

    - (void)setNetworkActivityIndicatorVisibleThreadSafe:(BOOL)networkActivityIndicatorVisible;

    - (UIBackgroundTaskIdentifier)requestBackgroundTask;
    - (void)handoffBackground:(NSNumber *)bgTask;
    - (void)handoffBackgroundUsingTimer:(NSNumber *)bgTask;

@end

#endif
