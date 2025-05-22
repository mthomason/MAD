//
//  MTBarcodeAusreDirect.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodeAusreDirect.h"

@interface MTBarcode ()

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) int16_t barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeAusreDirect

- (instancetype)init {
    if (self = [super init]) {

        self.barcodeType = [MTBarcodeAusreDirect type];
        self.name = @"Australia Post Redirect Code";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type { return MTBarcodeTypeAusreDirect; }

- (void)loadSampleData {
    self.input = @"39549554";
    self.primaryData = @"";
}

@end
