//
//  MADActivityIndicatorLabel.h
//  MAD
//
//  Created by Michael on 1/15/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADActivityIndicatorLabel_h
#define MAD_MADActivityIndicatorLabel_h

#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UILabel.h>

@interface MADActivityIndicatorLabel : UILabel

@end
#endif

#endif
