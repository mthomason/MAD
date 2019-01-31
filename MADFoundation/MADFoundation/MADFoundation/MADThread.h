//
//  MADThread.h
//  MAD
//
//  Created by Michael Thomason on 5/27/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

//#ifndef MADReports_NSThread_Extras_h
//#define MADReports_NSThread_Extras_h

#import <Foundation/NSObject.h>

@interface MADThread : NSObject

    + (void)completeOnMainThread:(void(^)(BOOL success, id obj))completion
                      withObject:(id)obj andSuccess:(BOOL)success;
    + (void)safeSwitchToMainThread:(void(^)(void))completion;

@end

//#endif
