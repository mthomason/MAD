//
//  MTBarcodeDatabarLimited.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodeDatabarLimited.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeDatabarLimited

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = MTBarcodeTypeRssLtd;
        self.name = @"Databar Limited";
        self.has2dComponent = YES;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeRssLtd;
}

- (void)loadSampleData {
    self.input = @"1110111110111";
    self.primaryData = @"";
}

@end
