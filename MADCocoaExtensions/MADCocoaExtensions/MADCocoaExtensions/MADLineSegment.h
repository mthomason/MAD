//
//  MADLineSegment.h
//  MADCocoaExtensions
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADLineSegment_h
#define MADLineSegment_h

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
