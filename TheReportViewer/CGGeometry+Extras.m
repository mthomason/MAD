//
//  CGGeometry+Extras.m
//  wordPuzzle
//
//  Created by Michael Thomason on 7/13/10.
//  Copyright 2010 Everyday Apps LLC. All rights reserved.
//

#import "CGGeometry+Extras.h"

//CG_INLINE
CGPoint CGPointMakeRandomOffscreen() {
	return randomOffscreenPoint(1);
}

//CG_INLINE
CGPoint randomOffscreenPoint(int multiple) {
	CGPoint offScreen;
	CGFloat offSetSize = 200.0000f * multiple;
	if (rand()%2 == 0) {
		if (rand()%2 == 0) {
			//offscreen top
			offScreen = CGPointMake(rand() % (int)1024.0000f, 0.0000f - offSetSize);
		} else {
			//offscreen left
			offScreen = CGPointMake(0.0000f - offSetSize, rand() % (int)1024.0000f);
		}
		
	} else {
		if (rand()%2 == 0) {
			//offscreen bottom
			offScreen = CGPointMake(rand() % (int)1024.0000f, 1024.0000f + offSetSize);
		} else {
			//offscreen right
			offScreen = CGPointMake(1024.0000f + offSetSize, rand() % (int)1024.0000f);
		}
	}
	return offScreen;
}

//CG_INLINE
CGFloat CGFloatPointsForInches(CGFloat inches) {
    return inches * 72.0000f;
}

//CG_INLINE
CGFloat CGFloatInchesForPoints(CGFloat points) {
    return points / 72.0000f;
}

//CG_INLINE
CGFloat CGFloatInchesForCentmeters(CGFloat centemeters) {
    return centemeters / 2.5400f;
}

//CG_INLINE
CGFloat CGFloatCentemetersForInches(CGFloat inches) {
    return inches * 2.5400f;
}