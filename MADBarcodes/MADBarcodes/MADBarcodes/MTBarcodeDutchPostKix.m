//
//  MTBarcodeDutchPostKix.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodeDutchPostKix.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) int16_t barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeDutchPostKix

- (instancetype)init {

    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeDutchPostKix type];
        self.name = @"Dutch Post KIX";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeKix;
}

- (void)loadSampleData {
    self.input = @"DUTCHPOSTKX";
    self.primaryData = @"";
}

@end
