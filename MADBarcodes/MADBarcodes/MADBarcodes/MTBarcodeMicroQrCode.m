//
//  MTBarcodeMicroQrCode.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeMicroQrCode.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, strong, readwrite) NSString *detailsSegueIdentifer;

    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeMicroQrCode

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeMicroQrCode type];
        self.name = @"Micro QR Code";
        self.detailsSegueIdentifer = @"MTIdentiferSegueBarcodeExtrasQrCode";
        self.has2dComponent = NO;
        self.hasOptionalInput = YES;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeMicroqr;
}

- (MTBarcodeSizingMode)sizingMode {
    MTBarcodeSizingMode result = MTBarcodeSizingModeAutomaticResizing;
    if (self.option1 == NO && self.option2 == NO && self.option3 == NO) {
        result = MTBarcodeSizingModeAutomaticResizing;
    } else if (self.option1 != NO) {
        result = MTBarcodeSizingModeSpecificErrorLevel;
    } else if (self.option2 != NO) {
        result = MTBarcodeSizingModeSpecificSize;
    }
    return result;
}

- (void)enableAutomaticResizing {
    [self setOption1:NO];
    [self setOption2:NO];
    [self setOption3:NO];
}
- (void)setSize:(NSInteger)size {
    [self setOption1:NO];
    self.option2 = size;
    [self setOption3:NO];
}
- (void)setMinmumErrorCorrection:(NSInteger)minmumErrorCorrection {
    self.option1 = minmumErrorCorrection;
    [self setOption2:NO];
    [self setOption3:NO];
}
- (NSInteger)size {
    return self.option2;
}
- (NSInteger)errorCorrection {
    return self.option1;
}

- (void)loadSampleData {
    self.input = @"http://www.everydayapps.com/";
    self.primaryData = @"";
}

@end
