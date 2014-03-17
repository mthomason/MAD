//
//  MTBarcodeCodeOne.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeCodeOne.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, retain, readwrite) NSString *detailsSegueIdentifer;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeCodeOne

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeCodeOne type]];
        [self setName: @"Code One"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: YES];
        [self setDetailsSegueIdentifer: @"MTIdentiferSegueBarcodeExtrasCodeOne"];
   
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeCodeOne;
}

- (void)setSize:(NSInteger)size {
    [self setOption2:size];
}

- (NSInteger)size {
    return [self option2];
}

- (void)initSampleData {
    [self setInput:              @"http://www.everydayapps.com/"];
    [self setPrimaryData:        @""];
}

@end
