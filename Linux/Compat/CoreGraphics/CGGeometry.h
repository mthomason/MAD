//
//  CGGeometry.h
//  Linux/Compat/CoreGraphics
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Apple's CoreGraphics geometry, off Apple.  GNUstep's Foundation already
//  carries the types -- CGFloat, CGPoint, CGSize and CGRect come in with
//  <CoreFoundation/CFCGTypes.h>, which <Foundation/NSGeometry.h> imports --
//  but none of the functions.  This header supplies the function set the
//  frameworks' layout code uses: the Make/Zero pair, the getters, the
//  predicates and the string conversions, all plain struct math with no
//  drawing behind them.  UIEdgeInsets is here too: it is the same four
//  CGFloat struct as NSEdgeInsets, and the formatter stores one.
//
//  It is reached as <CoreGraphics/CGGeometry.h> -- the directory one level up
//  is on the include path -- so the frameworks' Apple imports resolve
//  unchanged.  Non-Apple only; nothing on Apple sees it.
//

#ifndef MADCompat_CGGeometry_h
#define MADCompat_CGGeometry_h

#if !__APPLE__
#import <Foundation/NSGeometry.h>
#import <Foundation/NSString.h>
#include <math.h>

// CoreGraphics' spelling for a header-defined inline function.
#define CG_INLINE static inline

#pragma mark - Points

static const CGPoint CGPointZero __attribute__((unused)) = {0.0, 0.0};

static inline CGPoint CGPointMake(CGFloat x, CGFloat y) {
	CGPoint p; p.x = x; p.y = y; return p;
}

static inline BOOL CGPointEqualToPoint(CGPoint a, CGPoint b) {
	return a.x == b.x && a.y == b.y;
}

#pragma mark - Sizes

static const CGSize CGSizeZero __attribute__((unused)) = {0.0, 0.0};

static inline CGSize CGSizeMake(CGFloat width, CGFloat height) {
	CGSize s; s.width = width; s.height = height; return s;
}

static inline BOOL CGSizeEqualToSize(CGSize a, CGSize b) {
	return a.width == b.width && a.height == b.height;
}

#pragma mark - Rects

static const CGRect CGRectZero __attribute__((unused)) = {{0.0, 0.0}, {0.0, 0.0}};

static inline CGRect CGRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height) {
	CGRect r; r.origin.x = x; r.origin.y = y; r.size.width = width; r.size.height = height; return r;
}

static inline CGFloat CGRectGetMinX(CGRect r) { return r.origin.x; }
static inline CGFloat CGRectGetMidX(CGRect r) { return r.origin.x + r.size.width / 2.0; }
static inline CGFloat CGRectGetMaxX(CGRect r) { return r.origin.x + r.size.width; }
static inline CGFloat CGRectGetMinY(CGRect r) { return r.origin.y; }
static inline CGFloat CGRectGetMidY(CGRect r) { return r.origin.y + r.size.height / 2.0; }
static inline CGFloat CGRectGetMaxY(CGRect r) { return r.origin.y + r.size.height; }
static inline CGFloat CGRectGetWidth(CGRect r) { return r.size.width; }
static inline CGFloat CGRectGetHeight(CGRect r) { return r.size.height; }

static inline BOOL CGRectEqualToRect(CGRect a, CGRect b) {
	return CGPointEqualToPoint(a.origin, b.origin) && CGSizeEqualToSize(a.size, b.size);
}

static inline BOOL CGRectIsEmpty(CGRect r) {
	return r.size.width <= 0.0 || r.size.height <= 0.0;
}

static inline BOOL CGRectIsNull(CGRect r) {
	return r.origin.x == INFINITY && r.origin.y == INFINITY
		&& r.size.width == 0.0 && r.size.height == 0.0;
}

static inline BOOL CGRectIsInfinite(CGRect r) {
	return isinf(r.origin.x) && isinf(r.origin.y)
		&& isinf(r.size.width) && isinf(r.size.height);
}

static inline CGRect CGRectStandardize(CGRect r) {
	if (r.size.width < 0.0) { r.origin.x += r.size.width; r.size.width = -r.size.width; }
	if (r.size.height < 0.0) { r.origin.y += r.size.height; r.size.height = -r.size.height; }
	return r;
}

static inline CGRect CGRectOffset(CGRect r, CGFloat dx, CGFloat dy) {
	r.origin.x += dx; r.origin.y += dy;
	return r;
}

static inline CGRect CGRectInset(CGRect r, CGFloat dx, CGFloat dy) {
	r.origin.x += dx; r.origin.y += dy;
	r.size.width -= 2.0 * dx; r.size.height -= 2.0 * dy;
	return r;
}

static inline CGRect CGRectIntegral(CGRect r) {
	CGRect s = CGRectStandardize(r);
	CGFloat minX = floor(s.origin.x);
	CGFloat minY = floor(s.origin.y);
	CGFloat maxX = ceil(s.origin.x + s.size.width);
	CGFloat maxY = ceil(s.origin.y + s.size.height);
	return CGRectMake(minX, minY, maxX - minX, maxY - minY);
}

static inline BOOL CGRectContainsPoint(CGRect r, CGPoint p) {
	return p.x >= CGRectGetMinX(r) && p.x < CGRectGetMaxX(r)
		&& p.y >= CGRectGetMinY(r) && p.y < CGRectGetMaxY(r);
}

static inline BOOL CGRectIntersectsRect(CGRect a, CGRect b) {
	return !(CGRectGetMaxX(a) < CGRectGetMinX(b) || CGRectGetMaxX(b) < CGRectGetMinX(a)
		  || CGRectGetMaxY(a) < CGRectGetMinY(b) || CGRectGetMaxY(b) < CGRectGetMinY(a));
}

static inline BOOL CGRectContainsRect(CGRect a, CGRect b) {
	return CGRectGetMinX(b) >= CGRectGetMinX(a) && CGRectGetMaxX(b) <= CGRectGetMaxX(a)
		&& CGRectGetMinY(b) >= CGRectGetMinY(a) && CGRectGetMaxY(b) <= CGRectGetMaxY(a);
}

static inline CGRect CGRectIntersection(CGRect a, CGRect b) {
	if (!CGRectIntersectsRect(a, b)) return CGRectZero;
	CGFloat minX = MAX(CGRectGetMinX(a), CGRectGetMinX(b));
	CGFloat minY = MAX(CGRectGetMinY(a), CGRectGetMinY(b));
	CGFloat maxX = MIN(CGRectGetMaxX(a), CGRectGetMaxX(b));
	CGFloat maxY = MIN(CGRectGetMaxY(a), CGRectGetMaxY(b));
	return CGRectMake(minX, minY, maxX - minX, maxY - minY);
}

static inline CGRect CGRectUnion(CGRect a, CGRect b) {
	if (CGRectIsEmpty(a)) return b;
	if (CGRectIsEmpty(b)) return a;
	CGFloat minX = MIN(CGRectGetMinX(a), CGRectGetMinX(b));
	CGFloat minY = MIN(CGRectGetMinY(a), CGRectGetMinY(b));
	CGFloat maxX = MAX(CGRectGetMaxX(a), CGRectGetMaxX(b));
	CGFloat maxY = MAX(CGRectGetMaxY(a), CGRectGetMaxY(b));
	return CGRectMake(minX, minY, maxX - minX, maxY - minY);
}

#pragma mark - String conversions

static inline NSString *NSStringFromCGPoint(CGPoint p) {
	return [[NSString alloc] initWithFormat:@"{%g, %g}", (double)p.x, (double)p.y];
}

static inline NSString *NSStringFromCGSize(CGSize s) {
	return [[NSString alloc] initWithFormat:@"{%g, %g}", (double)s.width, (double)s.height];
}

static inline NSString *NSStringFromCGRect(CGRect r) {
	return [[NSString alloc] initWithFormat:@"{{%g, %g}, {%g, %g}}",
			(double)r.origin.x, (double)r.origin.y, (double)r.size.width, (double)r.size.height];
}

#pragma mark - Edge insets

// UIKit's edge insets are the same four-CGFloat struct as Foundation's
// NSEdgeInsets; the formatter stores one per page style.
typedef NSEdgeInsets UIEdgeInsets;

static const UIEdgeInsets UIEdgeInsetsZero __attribute__((unused)) = {0.0, 0.0, 0.0, 0.0};

static inline UIEdgeInsets UIEdgeInsetsMake(CGFloat top, CGFloat left, CGFloat bottom, CGFloat right) {
	UIEdgeInsets insets; insets.top = top; insets.left = left; insets.bottom = bottom; insets.right = right;
	return insets;
}

static inline CGRect UIEdgeInsetsInsetRect(CGRect rect, UIEdgeInsets insets) {
	return CGRectMake(rect.origin.x + insets.left,
					  rect.origin.y + insets.top,
					  rect.size.width - (insets.left + insets.right),
					  rect.size.height - (insets.top + insets.bottom));
}

#endif /* !__APPLE__ */

#endif /* MADCompat_CGGeometry_h */
