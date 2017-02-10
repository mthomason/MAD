//
//  MTBarcodeUkPlessey.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeUkPlessey.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeUkPlessey

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeUkPlessey type];
        self.name = @"UK Plessey";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypePlessey;
}

- (void)loadSampleData {
    self.input = @"87654321";
    self.primaryData = @"";
}

@end
