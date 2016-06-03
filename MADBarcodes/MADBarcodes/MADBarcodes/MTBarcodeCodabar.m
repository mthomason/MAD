//
//  MTBarcodeCodabar.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeCodabar.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeCodabar

- (instancetype)init {
    self = [super init];
    if (self) {
        
        self.barcodeType = [MTBarcodeCodabar type];
        self.name = @"Codabar";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeCODABAR;
}

- (void)initSampleData {
    self.input = @"9-$:/.+D";
    self.primaryData = @"";
}

@end
