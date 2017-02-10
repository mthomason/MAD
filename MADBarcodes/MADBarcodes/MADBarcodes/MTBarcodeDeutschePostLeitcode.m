//
//  MTBarcodeDeutschePostLeitcode.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeDeutschePostLeitcode.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeDeutschePostLeitcode

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = MTBarcodeTypeDPLEIT;
        self.name = @"Deutsche Post Leitcode";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type { return MTBarcodeTypeDPLEIT; }

- (void)loadSampleData {
    self.input = @"1111111111111";
    self.primaryData = @"";
}

@end
