//
//  MADBarcode.h
//  Barcodes
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MADBarcode_h
#define Barcodes_MADBarcode_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>

#import <MADBarcodes/MADBarcodeProtocol.h>
#import <MADBarcodes/MADBarcodeSizingMode.h>

@class MADColor;

@interface MADBarcode : NSObject <MADBarcodeProtocol>
	
	+ (instancetype)newBarcode:(id <MADBarcodeProtocol>)documentObject;
	+ (instancetype)newBarcode:(id <MADBarcodeProtocol>)documentObject
						input1:(NSString *)input1
						input2:(NSString *)input2;

	+ (instancetype)newBarcodeWithType:(MADBarcodeType)type;

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

	+ (NSString *)newBarcodeNameForType:(MADBarcodeType)type;
	+ (NSDictionary *)newDictionaryNames;

@end

#endif
