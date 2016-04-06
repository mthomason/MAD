//
//  MTBarcodeDatabarExpandedStacked.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeDatabarExpandedStacked.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, strong, readwrite) NSString *detailsSegueIdentifer;

    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeDatabarExpandedStacked

- (instancetype)init {

    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeDatabarExpandedStacked type];
        self.detailsSegueIdentifer = @"MTIdentiferSegueBarcodeExtrasDataBarExpandedStacked";
        self.name = @"Databar Expanded Stacked";
        self.has2dComponent = YES;
        self.hasOptionalInput = YES;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeRssExpstack;
}

- (NSInteger)numberOfDataColumns {
    return [self option2];
}

- (void)setNumberOfDataColumns:(NSInteger)numberOfDataColumns {
    [self setOption2:numberOfDataColumns];
}

- (void)initSampleData {
    [self setInput:              @"1666666666661"];
    [self setPrimaryData:        @""];
}

@end
