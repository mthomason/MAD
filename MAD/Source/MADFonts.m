//
//  MADFonts.m
//  MAD
//
//  Created by Michael Thomason on 2/29/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#include <TargetConditionals.h>
#import "MADFonts.h"
#if defined(__APPLE__) && TARGET_OS_OSX
#import <AppKit/NSFontManager.h>
#else
#import <UIKit/UIFont.h>
#endif

@interface MADFonts ()
@property (nonatomic, strong, readwrite) NSArray <NSString *> *familyNames;
@end

@implementation MADFonts

- (instancetype)init {
	if (self = [super init]) {
#if defined(__APPLE__) && TARGET_OS_OSX
		self.familyNames = [[[NSFontManager sharedFontManager] availableFontFamilies] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
#else
		self.familyNames = [[UIFont familyNames] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
#endif
	}
	return self;
}

@end
