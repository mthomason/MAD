//
//  MTBarcodeAusreply.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodeAusreply.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeAusreply

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = MTBarcodeTypeAusreply;
        self.name = @"Australia Post Reply-Paid";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeAusreply;
}

- (void)loadSampleData {
    self.input = @"39549554";
    self.primaryData = @"";
}

@end
