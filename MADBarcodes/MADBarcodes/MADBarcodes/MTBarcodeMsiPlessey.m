//
//  MTBarcodeMsiPlessey.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodeMsiPlessey.h"
#import <Foundation/NSException.h>

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, strong, readwrite) NSString *detailsSegueIdentifer;
    @property (nonatomic, assign, readwrite) int16_t barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeMsiPlessey

- (instancetype)init {

    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeMsiPlessey type];
        self.detailsSegueIdentifer = @"MTIdentiferSegueBarcodeExtrasMsiPlessey";
        self.name = @"MSI Plessey";
        self.has2dComponent = NO;
        self.hasOptionalInput = YES;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeMsiPlessey;
}

- (NSInteger)checkpointDigit {
    return self.option2;
}

- (void)setCheckDigit:(NSInteger)checkDigit {
    NSAssert(checkDigit == 0 || checkDigit == 1 || checkDigit == 2 || checkDigit == 3 || checkDigit == 4, @"Incorrect barcode check digit.");
    self.option2 = checkDigit;
}

- (void)loadSampleData {
    self.option2 = 0;
    self.input = @"87654321";
    self.primaryData = @"";
}

@end
