//
//  MADAffineTransformSwing.h
//  MAD
//
//  Created by Michael Thomason on 2/7/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADAffineTransformSwing_h
#define Reports_MADAffineTransformSwing_h

#import <CoreGraphics/CoreGraphics.h>
#import <math.h>

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0000f * M_PI)
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.00000f / M_PI))

static inline CGAffineTransform MADAffineTransformSwing(void);
static inline CGAffineTransform MADAffineTransformSwing(void) {
	return CGAffineTransformRotate(CGAffineTransformIdentity, DEGREES_TO_RADIANS(180.0000f));
}

#endif
