//
//  MTBarcodeUspsIntelligentMail.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeUspsIntelligentMail.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeUspsIntelligentMail

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = MTBarcodeTypeOneCode;
        self.name = @"USPS OneCode (Intelligent Mail)";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeOneCode;
}

- (void)loadSampleData {
    self.input = @"01234567094987654321-01234567891";
    self.primaryData = @"";
}

@end
