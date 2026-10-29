//
//  MADLabelTitle.h
//  MAD Designer
//
//  Created by Michael on 1/5/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADLabelTitle_h
#define MAD_MADLabelTitle_h

#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIView.h>

@interface MADLabelTitle : UIView

@property (nonatomic, copy) NSString *text;

@end
#endif

#endif
