//
//  MTBarcodeCode49.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodeCode49.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeCode49

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeCode49 type];
        self.name = @"Code 49";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeCODE49;
}

- (void)loadSampleData {
    self.input = self.name;
    self.primaryData = @"";
}

@end
