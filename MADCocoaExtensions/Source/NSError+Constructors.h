//
//  NSError+Constructors.h
//  MAD
//
//  Created by Michael Thomason on 4/1/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_NSError_Constructors_h
#define Reports_NSError_Constructors_h

#import <TargetConditionals.h>
#import <Foundation/NSError.h>

#if TARGET_OS_IPHONE
@class UIViewController;

@interface NSError (Constructors)

+ (void)presentError:(NSError *)error
	onViewController:(UIViewController *)viewController
		  completion:(void (^)(BOOL success))completion;

@end
#endif

#endif
