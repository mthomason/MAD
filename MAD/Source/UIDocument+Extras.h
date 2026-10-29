//
//  UIDocument+Extras.h
//  MAD
//
//  Created by Michael Thomason on 6/8/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MAD_UIDocument__Extras_h
#define Reports_MAD_UIDocument__Extras_h

#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIDocument.h>

@interface UIDocument (Extras)

- (void)deleteFromDiskCompletion:(void (^)(BOOL success))completion;

@end
#endif

#endif
