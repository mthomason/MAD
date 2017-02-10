//
//  MTBarcodeTelepenNumeric.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeTelepenNumeric.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeTelepenNumeric

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeTelepenNumeric type];
        self.name = @"Telepen Numeric";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeTelepenNum;
}

- (void)loadSampleData {
    self.input = @"466X33";
    self.primaryData = @"";
}

@end
