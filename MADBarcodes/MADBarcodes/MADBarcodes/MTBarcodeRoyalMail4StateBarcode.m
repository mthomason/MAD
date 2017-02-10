//
//  MTBarcodeRoyalMail4StateBarcode.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeRoyalMail4StateBarcode.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeRoyalMail4StateBarcode

- (instancetype)init {

    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeRoyalMail4StateBarcode type];
        self.name = @"Royal Mail 4-state Barcode";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeRm4scc;
}

- (void)loadSampleData {
    self.input = @"W1J0TR01";
    self.primaryData = @"";
}

@end
