//
//  NSValue+Geometry.m
//  Linux/Compat
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "NSValue+Geometry.h"

#if !__APPLE__

@implementation NSValue (MADCompatGeometry)

- (CGPoint)CGPointValue {
	return self.pointValue;
}

- (CGSize)CGSizeValue {
	return self.sizeValue;
}

- (CGRect)CGRectValue {
	return self.rectValue;
}

@end

#endif /* !__APPLE__ */
