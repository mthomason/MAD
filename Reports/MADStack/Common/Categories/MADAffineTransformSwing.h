//
//  MADAffineTransformSwing.h
//  MAD
//
//  Created by Michael Thomason on 2/7/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADAffineTransformSwing_h
#define Reports_MADAffineTransformSwing_h

#import <CoreGraphics/CoreGraphics.h>
#import <math.h>

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0000f * M_PI)
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.00000f / M_PI))

CG_INLINE CGAffineTransform MADAffineTransformSwing(void);
CG_INLINE CGAffineTransform
MADAffineTransformSwing() {
    return CGAffineTransformRotate(CGAffineTransformIdentity, DEGREES_TO_RADIANS(180.0000f));
}

#endif
