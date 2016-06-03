//
//  MTBarcodeDeutschePostIdentcode.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeDeutschePostIdentcode.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeDeutschePostIdentcode

- (instancetype)init {

    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeDeutschePostIdentcode type];
        self.name = @"Deutsche Post Identcode";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeDPIDENT;
}

- (void)initSampleData {
    self.input = @"11111111111";
    self.primaryData = @"";
}

@end
