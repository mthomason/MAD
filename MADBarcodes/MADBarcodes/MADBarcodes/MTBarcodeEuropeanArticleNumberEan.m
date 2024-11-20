//
//  MTBarcodeEuropeanArticleNumberEan.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodeEuropeanArticleNumberEan.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeEuropeanArticleNumberEan

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeEuropeanArticleNumberEan type];
        self.name = @"European Article Number (EAN)";
        self.has2dComponent = YES;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeEANX;
}

- (void)loadSampleData {
    self.input = @"54321";
    self.primaryData = @"";
}

@end
