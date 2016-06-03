//
//  MTBarcodeAusRoute.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeAusRoute.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeAusRoute

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = MTBarcodeTypeAusroute;
        self.name = @"Australia Post Routing Code";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type { return MTBarcodeTypeAusroute; }

- (void)initSampleData {
    self.input = @"39549554";
    self.primaryData = @"";
}

@end
