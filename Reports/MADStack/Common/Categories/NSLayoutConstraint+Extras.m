//
//  NSLayoutConstraint+Extras.m
//  MAD
//
//  Created by Michael Thomason on 9/4/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "NSLayoutConstraint+Extras.h"

@implementation NSLayoutConstraint (Extras)

// MARK: Use this to create debug description on NSLayoutConstraint
//        //NSLog(@"\n*****\nLayout constraint: \t%@ \n\t\t%@.%@\n\t\t\t %@\n\t\t %@.%@\n*****\n",
          //      constraint, constraint.firstItem,
          //      [self stringFromLayoutAttribute: constraint.firstAttribute],
          //      [self stringFromLayoutRelation: constraint.relation], constraint.secondItem,
          //      [self stringFromLayoutAttribute: constraint.secondAttribute]);

- (NSString *)stringFromLayoutRelation:(NSLayoutRelation)layoutRelation {
    switch (layoutRelation) {
        case NSLayoutRelationEqual:
            return @"==";
            break;
        case NSLayoutRelationGreaterThanOrEqual:
            return @">=";
            break;
        case NSLayoutRelationLessThanOrEqual:
            return @"<=";
            break;
        default:
            return @"";
            break;
    }
}

- (NSString *)stringFromLayoutAttribute:(NSLayoutAttribute)layoutAttribute {
    switch (layoutAttribute) {
        case NSLayoutAttributeNotAnAttribute:
            return @"NSLayoutAttributeNotAnAttribute";
            break;
        case NSLayoutAttributeBaseline:
            return @"NSLayoutAttributeBaseline";
            break;
        case NSLayoutAttributeBottom:
            return @"NSLayoutAttributeBottom";
            break;
        case NSLayoutAttributeBottomMargin:
            return @"NSLayoutAttributeBottomMargin";
            break;
        case NSLayoutAttributeCenterX:
            return @"NSLayoutAttributeCenterX";
            break;
        case NSLayoutAttributeCenterXWithinMargins:
            return @"NSLayoutAttributeCenterXWithinMargins";
            break;
        case NSLayoutAttributeCenterY:
            return @"NSLayoutAttributeCenterY";
            break;
        case NSLayoutAttributeCenterYWithinMargins:
            return @"NSLayoutAttributeCenterYWithinMargins";
            break;
        case NSLayoutAttributeFirstBaseline:
            return @"NSLayoutAttributeFirstBaseline";
            break;
        case NSLayoutAttributeHeight:
            return @"NSLayoutAttributeHeight";
            break;
        case NSLayoutAttributeLeading:
            return @"NSLayoutAttributeLeading";
            break;
        case NSLayoutAttributeLeadingMargin:
            return @"NSLayoutAttributeLeadingMargin";
            break;
        case NSLayoutAttributeLeft:
            return @"NSLayoutAttributeLeft";
            break;
        case NSLayoutAttributeLeftMargin:
            return @"NSLayoutAttributeLeftMargin";
            break;
        case NSLayoutAttributeRight:
            return @"NSLayoutAttributeRight";
            break;
        case NSLayoutAttributeRightMargin:
            return @"NSLayoutAttributeRightMargin";
            break;
        case NSLayoutAttributeTop:
            return @"NSLayoutAttributeTop";
            break;
        case NSLayoutAttributeTopMargin:
            return @"NSLayoutAttributeTopMargin";
            break;
        case NSLayoutAttributeTrailing:
            return @"NSLayoutAttributeTrailing";
            break;
        case NSLayoutAttributeTrailingMargin:
            return @"NSLayoutAttributeTrailingMargin";
            break;
        case NSLayoutAttributeWidth:
            return @"NSLayoutAttributeWidth";
            break;
        default:
            return @"";
            break;
    }
}

@end
