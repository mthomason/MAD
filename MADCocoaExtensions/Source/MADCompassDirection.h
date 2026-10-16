//
//  MADCompassDirection.h
//  MADCocoaExtensions
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADCompassDirection_h
#define MADCompassDirection_h

#import <Foundation/NSObjCRuntime.h>
#import <CoreGraphics/CGGeometry.h>

typedef NS_ENUM(NSUInteger, MADCompassDirection) {
	north = 1,
	south,
	east,
	west,
	northEast,
	northWest,
	southEast,
	southWest
};

CG_INLINE MADCompassDirection MADSpecificDirectionOfDegrees(double degrees);
CG_INLINE MADCompassDirection MADSpecificDirectionOfDegrees(double degrees) {
	while (degrees < 0.0) {
		degrees += 360.0;
	}
	while (degrees > 360.0) {
		degrees -= 360.0;
	}
	if (degrees >= 45.0 && degrees <= 135.0) {
		return north;
	} else if ( degrees >= 225.0 && degrees <= 315.0 ) {
		return south;
	} else if ((degrees >= 315.0 && degrees <= 360.0) || (degrees >= 0.0 && degrees <= 45.0)) {
		return east;
	} else if ( degrees >= 135.0 && degrees <= 225.0) {
		return west;
	} else {
		return north;
	}
}

#endif /* MADCompassDirection_h */
