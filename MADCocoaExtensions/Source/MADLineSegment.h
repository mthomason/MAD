//
//  MADLineSegment.h
//  MADCocoaExtensions
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADLineSegment_h
#define MADLineSegment_h

#import <CoreGraphics/CGGeometry.h>

struct MADLineSegment {
	CGPoint start;
	CGPoint end;
};
typedef struct MADLineSegment MADLineSegment;

CG_INLINE MADLineSegment MADLineSegmentMake(CGPoint p1, CGPoint p2);
CG_INLINE MADLineSegment MADLineSegmentMake(CGPoint p1, CGPoint p2) {
	MADLineSegment lineSegment;
	lineSegment.start = p1;
	lineSegment.end = p2;
	return lineSegment;
}

#endif /* MADLineSegment_h */
