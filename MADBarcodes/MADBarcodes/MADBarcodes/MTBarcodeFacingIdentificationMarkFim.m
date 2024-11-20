//
//  MTBarcodeFacingIdentificationMarkFim.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodeFacingIdentificationMarkFim.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeFacingIdentificationMarkFim

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeFacingIdentificationMarkFim type];
        self.name = @"Facing Identification Mark (FIM)";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeFim;
}

- (void)loadSampleData {
    self.input = @"A";
    self.primaryData = @"";
}

@end
