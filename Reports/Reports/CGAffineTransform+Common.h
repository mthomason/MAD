//
//  CGAffineTransform+Common.h
//  MAD
//
//  Created by Michael Thomason on 2/7/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0000f * M_PI)
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.00000f / M_PI))

CG_INLINE CGAffineTransform CGAffineTransformSwing();
CG_INLINE CGAffineTransform
CGAffineTransformSwing() {
    CGAffineTransform swingTransform = CGAffineTransformIdentity;
    return CGAffineTransformRotate(swingTransform, DEGREES_TO_RADIANS(180.0000f));
}
