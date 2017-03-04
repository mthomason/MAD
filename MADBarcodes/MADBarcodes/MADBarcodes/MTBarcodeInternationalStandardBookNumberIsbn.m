//
//  MTBarcodeInternationalStandardBookNumberIsbn.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeInternationalStandardBookNumberIsbn.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeInternationalStandardBookNumberIsbn

- (instancetype)init {

    if (self = [super init]) {
        
        self.barcodeType = MTBarcodeTypeIsbnX;
        self.name = @"International Standard Book Number (ISBN)";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return [MTBarcodeInternationalStandardBookNumberIsbn type];
}

- (void)loadSampleData {
    self.input = @"0812511816";
    self.primaryData = @"";
}

@end
