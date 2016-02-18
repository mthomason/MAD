//
//  MADAccessibilityLine.h
//  MAD
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIGeometry.h>
#import "MADDocumentObjectType.h"

@interface MADAccessibilityLine : NSObject

    - (instancetype)initWithValue:(id)value type:(MTDocumentObjectType)type andFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;

    @property (readonly) NSString *label;
    @property (readonly) CGRect frame;
    @property (nonatomic, assign, readonly) MTDocumentObjectType type;

@end
