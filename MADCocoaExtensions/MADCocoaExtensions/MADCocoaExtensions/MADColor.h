//
//  MADColor.h
//  MADCocoaExtensions
//
//  Created by Michael Thomason on 3/6/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

//#ifndef MADCocoaExtensions_MADColor_h
//#define MADCocoaExtensions_MADColor_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGBase.h>
#import <CoreGraphics/CGColorSpace.h>

extern const CGFloat MADF255;

@class UIColor;

UIColor *newColorWitColors(CGFloat r, CGFloat g, CGFloat b);
UIColor *newColorWithColorsAlpha(CGFloat r, CGFloat g, CGFloat b, CGFloat a);

@interface MADColor : NSObject
	<NSCopying>

	- (instancetype)initWithColor:(UIColor *)color;

	@property (nonatomic, copy, readonly) UIColor *color;

	@property (nonatomic, readonly) NSString *hexStringValue;

	@property (nonatomic, readonly) BOOL canProvideRGBComponents;
	@property (nonatomic, readonly) BOOL usesMonochromeColorspace;
	@property (nonatomic, readonly) BOOL usesRGBColorspace;
	@property (nonatomic, readonly) CGColorSpaceModel colorSpaceModel;

	@property (nonatomic, readonly) Byte redByte;
	@property (nonatomic, readonly) Byte greenByte;
	@property (nonatomic, readonly) Byte blueByte;
	@property (nonatomic, readonly) Byte alphaByte;
	@property (nonatomic, readonly) Byte whiteByte;

@end

//#endif
