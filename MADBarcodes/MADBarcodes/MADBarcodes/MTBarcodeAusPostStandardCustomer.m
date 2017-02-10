//
//  MTBarcodeAusPostStandardCustomer.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeAusPostStandardCustomer.h"

@interface MTBarcode ()

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeAusPostStandardCustomer

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeAusPostStandardCustomer type];
        self.name = @"Australia Post Standard Customer";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeAuspost;
}

- (void)loadSampleData {
    self.input = @"39549554";
    self.primaryData = @"";
}

@end
