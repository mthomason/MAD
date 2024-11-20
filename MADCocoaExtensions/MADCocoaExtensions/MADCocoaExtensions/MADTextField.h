//
//  MADTextField.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADTextField_h
#define MAD_Designer_MADTextField_h

#import <Foundation/NSObject.h>

@class UITextField;

typedef void (^MADTextFieldConfigurationHandler)(UITextField *textField);

@interface MADTextField : NSObject

    @property (readonly, nonatomic, copy) MADTextFieldConfigurationHandler handleConfigurePassword;
    @property (readonly, nonatomic, copy) MADTextFieldConfigurationHandler handleConfigureUsername;

@end

#endif
