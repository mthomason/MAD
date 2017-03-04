//
//  MTBarcodeUniversalProductCodeUpca.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeUniversalProductCodeUpca.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeUniversalProductCodeUpca

- (instancetype)init {
    
    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeUniversalProductCodeUpca type];
        self.name = @"Universal Product Code (UPC-A)";
        self.has2dComponent = YES;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeUpca;
}

- (void)loadSampleData {
    self.input = @"72527270270+12345";
    self.primaryData = @"";
}

@end
