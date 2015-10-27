//
//  MADAccessibilityLine.h
//  MAD
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIGeometry.h>

@interface MADAccessibilityLine : NSObject

    - (instancetype)initWithlabel:(NSString *)label andFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;

    @property (readonly) NSString *label;
    @property (readonly) CGRect frame;

@end
