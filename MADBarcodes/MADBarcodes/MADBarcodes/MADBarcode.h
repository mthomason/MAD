//
//  MADBarcode.h
//  Barcodes
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Barcodes_MADBarcode_h
#define Barcodes_MADBarcode_h

#import <TargetConditionals.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSData.h>
#import <CoreGraphics/CGGeometry.h>

#import <MADBarcodes/MADBarcodeProtocol.h>
#import <MADBarcodes/MADBarcodeSizingMode.h>

@class MADColor;
#if TARGET_OS_IPHONE
@class UIImage;
typedef UIImage MADBarcodeImage;
#elif TARGET_OS_OSX
@class NSImage;
typedef NSImage MADBarcodeImage;
#else
// Headless: the render core answers PNG bytes instead of a platform image.
typedef NSData MADBarcodeImage;
#endif

@interface MADBarcode : NSObject <MADBarcodeProtocol, NSSecureCoding>
	
	+ (instancetype)newBarcode:(id <MADBarcodeProtocol>)documentObject;
	+ (instancetype)newBarcode:(id <MADBarcodeProtocol>)documentObject
						input1:(NSString *)input1
						input2:(NSString *)input2;

	+ (instancetype)newBarcodeWithType:(MADBarcodeType)type;
	+ (MADBarcodeType)type;

	@property (nonatomic, readonly, strong) NSString *name;
	@property (nonatomic, readonly, strong) NSString *detailsSegueIdentifer;
	@property (nonatomic, copy)				NSString *primaryData;

	//@property (nonatomic, copy, readwrite)  MADColor *forgroundColor;
	//@property (nonatomic, copy, readonly)   MADColor *backgroundColor;
	@property (nonatomic, assign, readonly) BOOL has2dComponent;
	@property (nonatomic, assign, readonly) BOOL hasOptionalInput;

	@property (nonatomic, assign) BOOL center;

	@property (nonatomic, retain) NSString *input;
	@property (nonatomic, assign) NSInteger width;
	@property (nonatomic, assign) NSInteger has2dComponentType;

	- (void)drawInRect:(CGRect)rect;
	- (void)loadSampleData;

	// The encoded symbol as one image, in zint's natural orientation and at one
	// point per bitmap pixel.  nil when zint refuses the inputs.
	- (MADBarcodeImage *)renderedImage;

	// The encoded symbol as PNG bytes (8-bit RGB, opaque), in zint's natural
	// orientation and one pixel per bitmap pixel.  nil when zint refuses the
	// inputs.  The UIKit-free render core, available on every platform.
	- (NSData *)renderedPNGData;

	// The same, reporting the message from the zint pass that failed.
	- (NSData *)renderedPNGDataWithErrorMessage:(NSString * __autoreleasing *)errorMessage;

	// Canonical key over every value that changes what -renderedImage or
	// -drawInRect: produces, for MADBarcodeCache.
	- (NSString *)renderCacheKey;

	+ (NSString *)newBarcodeNameForType:(MADBarcodeType)type;
	+ (NSDictionary *)newDictionaryNames;

@end

#endif
