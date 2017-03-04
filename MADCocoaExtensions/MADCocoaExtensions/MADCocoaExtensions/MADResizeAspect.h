//
//  MADResizeAspect.h
//  MADCocoaExtensions
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADResizeAspect_h
#define MADResizeAspect_h

#import "MADAspectRatio.h"
#import "MADCompassDirection.h"
#import "MAD2dDirection.h"

struct MADResizeAspect {
    MADAspectRatio aspectRatio;
    MAD2dDirection direction;
};

static inline struct MADResizeAspect MADResizeTypeForDirection(MADCompassDirection direction);
static inline struct MADResizeAspect MADResizeTypeForDirection(MADCompassDirection direction) {
    struct MADResizeAspect resizeAspect;
    switch (direction) {
        case south:
        case north:
            resizeAspect.aspectRatio = stretch;
            resizeAspect.direction = vertical;
            break;
        case east:
        case west:
            resizeAspect.aspectRatio = stretch;
            resizeAspect.direction = horizontal;
            break;
        case northEast:
        case northWest:
        case southEast:
        case southWest:
            resizeAspect.aspectRatio = fixed;
            resizeAspect.direction = diagonal;
            break;
        default:
            resizeAspect.aspectRatio = stretch;
            resizeAspect.direction = horizontal;
            break;
    }
    return resizeAspect;
}

#endif /* MADResizeAspect_h */
