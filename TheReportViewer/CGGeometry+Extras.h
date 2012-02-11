//
//  CGGeometry+Extras.h
//  wordPuzzle
//
//  Created by Michael Thomason on 7/13/10.
//  Copyright 2010 Everyday Apps LLC. All rights reserved.
//

/* Make a point from `(x, y)'. */

CG_INLINE CGPoint CGPointMakeRandomOffscreen();

CGPoint randomOffscreenPoint(int multiple);

CG_INLINE CGFloat CGFloatPointsForInches(CGFloat inches);
CG_INLINE CGFloat CGFloatInchesForPoints(CGFloat points);
CG_INLINE CGFloat CGFloatInchesForCentmeters(CGFloat centemeters);
CG_INLINE CGFloat CGFloatCentemetersForInches(CGFloat inches);