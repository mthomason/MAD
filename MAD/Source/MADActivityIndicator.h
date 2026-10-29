//
//  MADActivityIndicator.h
//  MAD
//
//  Created by Michael Thomason on 7/20/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADActivityIndicator_h
#define MAD_MADActivityIndicator_h

#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIView.h>

@class UILabel;

@interface MADActivityIndicator : UIView

	@property (nonatomic, strong) UILabel *status;

@end
#endif

#endif
