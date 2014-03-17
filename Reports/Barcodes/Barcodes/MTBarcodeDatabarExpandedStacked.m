//
//  MTBarcodeDatabarExpandedStacked.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeDatabarExpandedStacked.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, retain, readwrite) NSString *detailsSegueIdentifer;

@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeDatabarExpandedStacked

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeDatabarExpandedStacked type]];
        [self setDetailsSegueIdentifer:@"MTIdentiferSegueBarcodeExtrasDataBarExpandedStacked"];
        [self setName: @"Databar Expanded Stacked"];
        [self setHas2dComponent: YES];
        [self setHasOptionalInput: YES];
        
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
