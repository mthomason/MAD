//
//  MADLabel.h
//  MADCocoaExtensions
//
//  Created by Michael Thomason on 3/1/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADExtensions_MADLabel_h
#define MADExtensions_MADLabel_h

#import <UIKit/UILabel.h>

@interface MADLabel : UILabel

+ (instancetype)newDocumentCaption:(CGRect)frame width:(CGFloat)width NS_RETURNS_RETAINED;

@end

#endif
