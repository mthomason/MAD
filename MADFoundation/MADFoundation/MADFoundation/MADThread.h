//
//  MADThread.h
//  MAD
//
//  Created by Michael Thomason on 5/27/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import <Foundation/NSObject.h>

@interface MADThread : NSObject

	+ (void)completeOnMainThread:(void(^)(BOOL success, id obj))completion
					  withObject:(id)obj andSuccess:(BOOL)success;
	+ (void)safeSwitchToMainThread:(void(^)(void))completion;

@end
