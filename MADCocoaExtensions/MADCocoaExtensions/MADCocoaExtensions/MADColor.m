//
//  MADColor.m
//  MADCocoaExtensions
//
//  Created by Michael Thomason on 3/6/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADColor.h"
#import <UIKit/UIColor.h>
#import <CoreGraphics/CGColorSpace.h>

const CGFloat MADF255 = 255.00000000f;

UIColor *newColorWitColors(CGFloat r, CGFloat g, CGFloat b) {
	return [[UIColor alloc] initWithRed:r/MADF255 green:g/MADF255 blue:b/MADF255 alpha:1.00000000f];
}

UIColor *newColorWithColorsAlpha(CGFloat r, CGFloat g, CGFloat b, CGFloat a) {
	return [[UIColor alloc] initWithRed:r/MADF255 green:g/MADF255 blue:b/MADF255 alpha:a];
}

@interface MADColor ()
	@property (nonatomic, copy, readwrite) UIColor *color;
@end

@implementation MADColor

- (instancetype)initWithColor:(UIColor *)color {
	if (self = [super init]) {
		_color = color.copy;
	}
	return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
	id copy = [[MADColor alloc] initWithColor:self.color];
	return copy;
}

- (NSString *)hexStringValue {
	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -hexStringValue");
	NSString *result;
	
	switch (self.colorSpaceModel) {
		case kCGColorSpaceModelRGB:
			result = [[NSString alloc] initWithFormat:@"%02X%02X%02X",
												self.redByte, self.greenByte, self.blueByte];
			break;
			
		case kCGColorSpaceModelMonochrome:
			result = [[NSString alloc] initWithFormat:@"%02X%02X%02X",
												self.whiteByte, self.whiteByte, self.whiteByte];
			break;
			
		default:
			result = nil;
	}
	return result;
}

/// Supports either RGB or W

- (BOOL)canProvideRGBComponents {
	switch (self.colorSpaceModel) {
		case kCGColorSpaceModelRGB:
		case kCGColorSpaceModelMonochrome:
			return YES;
		default:
			return NO;
	}
}

// Convenience: Test for Monochrome
- (BOOL)usesMonochromeColorspace {
	return (self.colorSpaceModel == kCGColorSpaceModelMonochrome);
}

// Convenience: Test for RGB
- (BOOL)usesRGBColorspace {
	return (self.colorSpaceModel == kCGColorSpaceModelRGB);
}

- (CGColorSpaceModel)colorSpaceModel {
	return CGColorSpaceGetModel(CGColorGetColorSpace(self.color.CGColor));
}

static inline Byte byteFromColor(CGFloat color);
static inline Byte byteFromColor(CGFloat color) {
	return (Byte)(color * 0xFF) & 0xFF;
};

- (Byte) redByte { return byteFromColor(self.red); }
- (Byte) greenByte { return byteFromColor(self.green); }
- (Byte) blueByte { return byteFromColor(self.blue); }
- (Byte) alphaByte { return byteFromColor(self.alpha); }
- (Byte) whiteByte { return byteFromColor(self.white); };

#pragma mark - Component Properties

- (CGFloat)red {

	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -red");
	CGFloat r = 0.0f;
	
	switch (self.colorSpaceModel) {
		case kCGColorSpaceModelRGB:
			[self.color getRed:&r green:NULL blue:NULL alpha:NULL];
			break;
		case kCGColorSpaceModelMonochrome:
			[self.color getWhite:&r alpha:NULL];
		default:
			break;
	}
	
	return r;
}

- (CGFloat)green {

	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -green");
	CGFloat g = 0.0f;
	
	switch (self.colorSpaceModel)
	{
		case kCGColorSpaceModelRGB:
			[self.color getRed:NULL green:&g blue:NULL alpha:NULL];
			break;
		case kCGColorSpaceModelMonochrome:
			[self.color getWhite:&g alpha:NULL];
		default:
			break;
	}
	
	return g;
}

- (CGFloat)blue {
	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -blue");
	CGFloat b = 0.0f;
	
	switch (self.colorSpaceModel)
	{
		case kCGColorSpaceModelRGB:
			[self.color getRed:NULL green:NULL blue:&b alpha:NULL];
			break;
		case kCGColorSpaceModelMonochrome:
			[self.color getWhite:&b alpha:NULL];
		default:
			break;
	}
	
	return b;
}

- (CGFloat)alpha {
	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -alpha");
	CGFloat a = 0.0f;
	
	switch (self.colorSpaceModel) {
		case kCGColorSpaceModelRGB:
			[self.color getRed:NULL green:NULL blue:NULL alpha:&a];
			break;
		case kCGColorSpaceModelMonochrome:
			[self.color getWhite:NULL alpha:&a];
		default:
			break;
	}
	
	return a;
}

- (CGFloat)white {
	NSAssert(self.usesMonochromeColorspace, @"Must be a Monochrome color to use -white");
	
	CGFloat w;
	[self.color getWhite:&w alpha:NULL];
	return w;
}


- (CGFloat)hue {
	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -hue");
	CGFloat h = 0.0f;
	
	switch (self.colorSpaceModel) {
		case kCGColorSpaceModelRGB:
			[self.color getHue: &h saturation:NULL brightness:NULL alpha:NULL];
			break;
		case kCGColorSpaceModelMonochrome:
			[self.color getWhite:&h alpha:NULL];
		default:
			break;
	}
	
	return h;
}

- (CGFloat)saturation {
	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -saturation");
	CGFloat s = 0.0f;
	
	switch (self.colorSpaceModel) {
		case kCGColorSpaceModelRGB:
			[self.color getHue:NULL saturation: &s brightness:NULL alpha:NULL];
			break;
			
		case kCGColorSpaceModelMonochrome:
			[self.color getWhite:&s alpha:NULL];
			
		default:
			break;
	}
	
	return s;
}

- (CGFloat)brightness {
	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -brightness");
	CGFloat v = 0.0f;
	
	switch (self.colorSpaceModel) {
		case kCGColorSpaceModelRGB:
			[self.color getHue:NULL saturation:NULL brightness: &v alpha:NULL];
			break;
			
		case kCGColorSpaceModelMonochrome:
			[self.color getWhite:&v alpha:NULL];
			
		default:
			break;
	}
	
	return v;
}

- (CGFloat)luminance {
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use -luminance");
	
	CGFloat r, g, b;
	if (![self.color getRed: &r green: &g blue: &b alpha:NULL])
		return 0.0f;
	
	// http://en.wikipedia.org/wiki/Luma_(video)
	// Y = 0.2126 R + 0.7152 G + 0.0722 B
	return r * 0.2126f + g * 0.7152f + b * 0.0722f;
}

@end
