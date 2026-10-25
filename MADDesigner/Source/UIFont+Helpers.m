//
//  UIFont+Helpers.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/22/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "UIFont+Helpers.h"

@implementation UIFont (Helpers)

+ (void)LogFonts {
#if DEBUG
	for (NSString* family in [UIFont familyNames]) {
		NSLog(@"%@", family);
		for (NSString* name in [UIFont fontNamesForFamilyName: family]) {
			NSLog(@"  %@", name);
		}
	}
#endif
}

@end
