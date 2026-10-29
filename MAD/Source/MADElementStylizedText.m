//
//  MADocumentObjectTextAttributes.m
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADElementStylizedText.h"
#import "UIFontDescriptor+MADAdditions.h"
#import "RptqDocumentElement.h"
#import "RptqTextStyle.h"
#import "MADAlignment.h"

#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

#include <TargetConditionals.h>
#if defined(__APPLE__) && TARGET_OS_OSX
#import <AppKit/AppKit.h>
#else
#import <UIKit/UIFontDescriptor.h>
#import <UIKit/UIFont.h>
#import <UIKit/NSParagraphStyle.h>
#import <UIKit/NSAttributedString.h>
#endif

@interface MADElementStylizedText ()

@property (nonatomic, strong, readwrite) NSMutableDictionary *fontAttributes;
- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end

@implementation MADElementStylizedText

- (instancetype)init {
	self = [super init];
	return self;
}

- (nullable instancetype)initWithFontName:(NSString * _Nullable) fontname
								 fontSize:(double) fontsize
								textStyle:(RptqTextStyle *)textStyle
					  horizontalAlignment:(MADHorizontalAlignment)horizontalAlignment {
	
	if (self = [super init]) {
		
		MADPlatformFontDescriptor *fontDescriptor = [MADPlatformFontDescriptor newFontDescriptorForFontName: fontname
																								   fontSize: fontsize
																									   bold: textStyle.bold
																									 italic: textStyle.italic];
		
#if defined(__APPLE__) && TARGET_OS_OSX
		NSFont *customFont = [NSFont fontWithDescriptor: fontDescriptor
												   size: 0.0];
		if (customFont == nil) {
			customFont = [NSFont systemFontOfSize: (fontsize > 0.0 ? fontsize : 12.0)];
		}
#else
		UIFont *customFont = [UIFont fontWithDescriptor: fontDescriptor
												   size: 0.0];
#endif
		
		
		NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		// ???: Where is NSLineBreakByClipping in iOS7... There attributed string is buggy as fuck.
		paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
		paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
		
		switch (horizontalAlignment) {
			case MADHorizontalAlignmentLeft:
				paragraphStyle.alignment = NSTextAlignmentLeft;
				break;
			case MADHorizontalAlignmentRight:
				paragraphStyle.alignment = NSTextAlignmentRight;
				break;
			case MADHorizontalAlignmentCenter:
				paragraphStyle.alignment = NSTextAlignmentCenter;
				break;
			case MADHorizontalAlignmentJustified:
				paragraphStyle.alignment = NSTextAlignmentJustified;
				break;
			case MADHorizontalAlignmentNatrual:
				paragraphStyle.alignment = NSTextAlignmentNatural;
				break;
			default:
				paragraphStyle.alignment = NSTextAlignmentLeft;
				break;
		}
		
		NSNumber *underlineStyle = [[NSNumber alloc] initWithInteger: textStyle.underline ? NSUnderlineStyleSingle : NSUnderlineStyleNone];
		NSNumber *strikethroughStyle = [[NSNumber alloc] initWithInteger: textStyle.strikethrough ? NSUnderlineStyleSingle : NSUnderlineStyleNone];
		NSMutableDictionary *fontAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
											   customFont,			NSFontAttributeName,
											   @0.0,				NSBaselineOffsetAttributeName,
											   underlineStyle,		NSUnderlineStyleAttributeName,
											   strikethroughStyle,	NSStrikethroughStyleAttributeName,
											   paragraphStyle,		NSParagraphStyleAttributeName, nil];
		
		self.fontAttributes = fontAttributes;
		
	}
	return self;
	
}

@end
