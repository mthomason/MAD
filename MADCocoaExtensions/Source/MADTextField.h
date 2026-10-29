//
//  MADTextField.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADTextField_h
#define MAD_Designer_MADTextField_h

#import <TargetConditionals.h>
#import <Foundation/NSObject.h>

#if TARGET_OS_IPHONE
@class UITextField;

typedef void (^MADTextFieldConfigurationHandler)(UITextField *textField);

@interface MADTextField : NSObject

@property (readonly, nonatomic, copy) MADTextFieldConfigurationHandler handleConfigurePassword;
@property (readonly, nonatomic, copy) MADTextFieldConfigurationHandler handleConfigureUsername;

@end
#endif

#endif
