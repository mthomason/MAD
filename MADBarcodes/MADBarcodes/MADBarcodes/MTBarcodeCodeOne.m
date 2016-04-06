//
//  MTBarcodeCodeOne.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeCodeOne.h"

@interface MTBarcode ()

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *detailsSegueIdentifer;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeCodeOne

- (instancetype)init {
    self = [super init];
    if (self) {
        
        self.barcodeType = [MTBarcodeCodeOne type];
        self.name = @"Code One";
        self.has2dComponent = NO;
        self.hasOptionalInput = YES;
        self.detailsSegueIdentifer = @"MTIdentiferSegueBarcodeExtrasCodeOne";
   
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
