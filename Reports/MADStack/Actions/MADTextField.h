//
//  MADTextField.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADTextField_h
#define MAD_Designer_MADTextField_h

#import <Foundation/NSObject.h>

@class UITextField;

@interface MADTextField : NSObject

    + (void)configureTextFieldForPassword:(UITextField * __autoreleasing *)textField;
    + (void)configureTextFieldForUsername:(UITextField * __autoreleasing *)textField;

@end

#endif
