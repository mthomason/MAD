//
//  UIFontDescriptor+DocumentObject.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "UIFontDescriptor+MADAdditions.h"

#if defined(__APPLE__) && TARGET_OS_OSX
@implementation NSFontDescriptor (MADAdditions)
#else
@implementation UIFontDescriptor (MADAdditions)
#endif

+ (instancetype)newFontDescriptorForFontName:(NSString *) fontName
									fontSize:(double) fontSize
										bold:(BOOL)bold italic:(BOOL)italic {
#if defined(__APPLE__) && TARGET_OS_OSX
	NSFontDescriptorSymbolicTraits traits = 0;
	if (bold)   traits     |= NSFontDescriptorTraitBold;
	if (italic) traits     |= NSFontDescriptorTraitItalic;

	NSDictionary *traitsDict = @{NSFontSymbolicTrait: @(traits)};
	NSDictionary *attributes = @{
		NSFontFamilyAttribute: fontName,
		NSFontTraitsAttribute: traitsDict,
		NSFontSizeAttribute: @(fontSize)
	};
	return [[NSFontDescriptor alloc] initWithFontAttributes:attributes];
#else
	UIFontDescriptorSymbolicTraits traits = 0;
	if (bold)   traits     |= UIFontDescriptorTraitBold;
	if (italic) traits     |= UIFontDescriptorTraitItalic;

	NSDictionary *traitsDict = @{UIFontSymbolicTrait: @(traits)};
	NSDictionary *attributes = @{
		UIFontDescriptorFamilyAttribute: fontName,
		UIFontDescriptorTraitsAttribute: traitsDict,
		UIFontDescriptorSizeAttribute: @(fontSize)
	};
	return [[UIFontDescriptor alloc] initWithFontAttributes:attributes];
#endif
}

@end
