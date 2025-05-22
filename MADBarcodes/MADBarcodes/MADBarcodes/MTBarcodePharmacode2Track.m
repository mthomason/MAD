//
//  MTBarcodePharmacode2Track.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodePharmacode2Track.h"

@interface MTBarcode ()

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) int16_t barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodePharmacode2Track

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodePharmacode2Track type];
        self.name = @"Pharmacode 2-track";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypePharmaTwo;
}

- (void)loadSampleData {
    self.input = @"64570080";
    self.primaryData = @"";
}

@end
