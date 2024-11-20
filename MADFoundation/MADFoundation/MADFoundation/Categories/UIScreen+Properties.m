//
//  UIScreen+Properties.m
//  MADFoundation
//
//  Created by Michael Thomason on 6/8/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "UIScreen+Properties.h"

#if TARGET_OS_MACCATALYST || TARGET_OS_IOS
@implementation UIScreen (Properties)

- (BOOL)isRetinaDisplay {
	return self.scale > 1.0;
}

#elif TARGET_OS_OSX
@implementation NSScreen (Properties)

- (BOOL)isRetinaDisplay {
	return self.backingScaleFactor > 1.0;
}

#endif

@end
