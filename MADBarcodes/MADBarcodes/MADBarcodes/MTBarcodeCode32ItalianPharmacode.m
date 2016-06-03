//
//  MTBarcodeCode32ItalianPharmacode.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeCode32ItalianPharmacode.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeCode32ItalianPharmacode

- (instancetype)init {
    
    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeCode32ItalianPharmacode type];
        self.name = @"Code 32 (Italian Pharmacode)";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeCode32;
}

- (void)initSampleData {
    self.input = @"27182818";
    self.primaryData = @"";
}

@end
