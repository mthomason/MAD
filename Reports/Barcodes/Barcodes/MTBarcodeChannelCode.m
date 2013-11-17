//
//  MTBarcodeChannelCode.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeChannelCode.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, retain, readwrite) NSString *detailsSegueIdentifer;

@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeChannelCode

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeChannelCode type]];
        [self setDetailsSegueIdentifer:@"MTIdentiferSegueBarcodeExtrasChannelCode"];
        [self setName: @"Channel Code"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: YES];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeChannel;
}

- (void)setNumberOfChannels:(NSInteger)numberOfChannels {
    [self setOption2:numberOfChannels];
}

- (NSInteger)numberOfChannels {
    return [self option2];
}

@end
