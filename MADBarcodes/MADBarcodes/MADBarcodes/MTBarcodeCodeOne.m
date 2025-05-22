//
//  MTBarcodeCodeOne.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodeCodeOne.h"

@interface MTBarcode ()

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *detailsSegueIdentifer;
@property (nonatomic, assign, readwrite) int16_t barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeCodeOne

- (instancetype)init {
    if (self = [super init]) {
        
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
    self.option2 = size;
}

- (NSInteger)size {
    return self.option2;
}

- (void)loadSampleData {
    self.input = @"http://www.everydayapps.com/";
    self.primaryData = @"";
}

@end
