//
//  UIFontDescriptor+DocumentObject.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "UIFontDescriptor+MADAdditions.h"

@implementation UIFontDescriptor (MADAdditions)

+ (instancetype)newFontDescriptorForFontName:(NSString *) fontName
									fontSize:(double) fontSize
										bold:(BOOL)bold italic:(BOOL)italic {
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
}

@end
