//
//  MADColor.h
//  MADCocoaExtensions
//
//  Created by Michael Thomason on 3/6/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADCocoaExtensions__MADColor_h
#define MADCocoaExtensions__MADColor_h

#import <Foundation/NSObject.h>
#if __APPLE__
#import <TargetConditionals.h>
#endif
#import <CoreGraphics/CGBase.h>
#import <CoreGraphics/CGColorSpace.h>

extern const CGFloat MADF255;

#if defined(TARGET_OS_OSX) && TARGET_OS_OSX
@class NSColor;
typedef NSColor MADPlatformColor;
#else
@class UIColor;
typedef UIColor MADPlatformColor;
#endif

MADPlatformColor *newColorWitColors(CGFloat r, CGFloat g, CGFloat b);
MADPlatformColor *newColorWithColorsAlpha(CGFloat r, CGFloat g, CGFloat b, CGFloat a);

@interface MADColor : NSObject <NSCopying>

- (instancetype)initWithColor:(MADPlatformColor *)color;

@property (nonatomic, copy, readonly) MADPlatformColor *color;

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

#endif
