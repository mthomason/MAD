//
//  MADTextField.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/NSObject.h>

@class UITextField;

@interface MADTextField : NSObject

+ (void)configureTextFieldForPassword:(UITextField * __autoreleasing *)textField;

@end
