//
//  MTBarcodePlanet.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodePlanet.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodePlanet

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = MTBarcodeTypePlanet;
        self.name = @"PLANET";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type { return MTBarcodeTypePlanet; }

- (void)loadSampleData {
    self.input = @"1231231231231";
    self.primaryData = @"";
}

@end
