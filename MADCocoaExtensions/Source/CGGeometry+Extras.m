//
//  CGGeometry+Extras.m
//  wordPuzzle
//
//  Created by Michael Thomason on 7/13/10.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "CGGeometry+Extras.h"

const double MADZero                        =    0.0;
const double MAD_2                          =    2.0;
const double MAD_44                         =   44.0;
const double MAD_45                         =   45.0;
const double MAD_64                         =   64.0;
const double MAD_320                        =  320.0;
const double MAD_360                        =  360.0;
const double MADDefaultHeight               = MAD_44;
const double MADHeaderHeight                = MAD_45;

const CGFloat MADFloatHeaderHeight          = MAD_45;
const CGFloat MADFloatZero                  =    0.00000000f;
const CGFloat MADFloat_64                   =   64.00000000f;
const CGFloat MADFloat_320                  =  320.00000000f;
const CGFloat MADFloat_1024                 = 1024.00000000f;
const CGFloat MTDefaultFingerSizeWidth      =   44.00000000f;
const CGFloat MTDefaultFingerSizeHeight     = MTDefaultFingerSizeWidth;

#if defined(TARGET_OS_OSX) && TARGET_OS_OSX
@implementation NSValue (MADCGGeometryExtensions)

+ (NSValue *)valueWithCGPoint:(CGPoint)point {
	return [NSValue valueWithPoint:NSPointFromCGPoint(point)];
}

+ (NSValue *)valueWithCGSize:(CGSize)size {
	return [NSValue valueWithSize:NSSizeFromCGSize(size)];
}

+ (NSValue *)valueWithCGRect:(CGRect)rect {
	return [NSValue valueWithRect:NSRectFromCGRect(rect)];
}

- (CGPoint)CGPointValue {
	return NSPointToCGPoint(self.pointValue);
}

- (CGSize)CGSizeValue {
	return NSSizeToCGSize(self.sizeValue);
}

- (CGRect)CGRectValue {
	return NSRectToCGRect(self.rectValue);
}

@end
#endif

