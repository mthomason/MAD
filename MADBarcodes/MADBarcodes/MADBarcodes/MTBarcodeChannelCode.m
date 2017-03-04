//
//  MTBarcodeChannelCode.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeChannelCode.h"

@interface MTBarcode ()

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *detailsSegueIdentifer;

@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeChannelCode

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeChannelCode type];
        self.detailsSegueIdentifer = @"MTIdentiferSegueBarcodeExtrasChannelCode";
        self.name = @"Channel Code";
        self.has2dComponent = NO;
        self.hasOptionalInput = YES;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeChannel;
}

- (void)setNumberOfChannels:(NSInteger)numberOfChannels {
    self.option2 = numberOfChannels;
}

- (NSInteger)numberOfChannels {
    return self.option2;
}

- (void)loadSampleData {
    [self setNumberOfChannels:   4];
    self.input = @"257";
    self.primaryData = @"";
}

@end
