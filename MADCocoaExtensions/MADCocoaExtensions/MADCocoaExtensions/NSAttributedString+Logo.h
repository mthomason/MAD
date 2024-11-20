//
//  NSAttributedString+Logo.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/7/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_NSAttributedString_Logo_h
#define MAD_Designer_NSAttributedString_Logo_h

#import <Foundation/NSAttributedString.h>

@interface MADAttributedStringLogo : NSAttributedString

    + (instancetype)newLogoStringForTitle:(NSString *)title;

@end

#endif
