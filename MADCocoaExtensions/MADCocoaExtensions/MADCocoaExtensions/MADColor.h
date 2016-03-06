//
//  MADColor.h
//  MADCocoaExtensions
//
//  Created by Michael Thomason on 3/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIColor.h>

extern const CGFloat MADF255;

static inline UIColor *newColorWitColors(CGFloat r, CGFloat g, CGFloat b);
static inline UIColor *newColorWitColors(CGFloat r, CGFloat g, CGFloat b) {
    return [[UIColor alloc] initWithRed:r/MADF255 green:g/MADF255 blue:b/MADF255 alpha:1.00000000f];
}

static inline UIColor *newColorWithColorsAlpha(CGFloat r, CGFloat g, CGFloat b, CGFloat a);
static inline UIColor *newColorWithColorsAlpha(CGFloat r, CGFloat g, CGFloat b, CGFloat a) {
    return [[UIColor alloc] initWithRed:r/MADF255 green:g/MADF255 blue:b/MADF255 alpha:a];
}

@interface MADColor : NSObject


@end
