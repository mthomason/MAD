//
//  MTBarcodeItf14.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodeItf14.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeItf14

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeItf14 type];
        self.name = @"ITF-14";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeItf14;
}

- (void)loadSampleData {
    self.input = @"9891234567890";
    self.primaryData = @"";
}

@end
