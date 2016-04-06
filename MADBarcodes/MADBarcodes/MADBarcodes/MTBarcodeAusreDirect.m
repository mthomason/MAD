//
//  MTBarcodeAusreDirect.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeAusreDirect.h"

@interface MTBarcode ()

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeAusreDirect

- (instancetype)init {
    self = [super init];
    if (self) {

        self.barcodeType = [MTBarcodeAusreDirect type];
        self.name = @"Australia Post Redirect Code";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type { return MTBarcodeTypeAusreDirect; }

- (void)initSampleData {
    [self setInput:              @"39549554"];
    [self setPrimaryData:        @""];
}

@end
