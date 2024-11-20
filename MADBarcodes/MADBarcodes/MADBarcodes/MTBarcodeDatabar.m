//
//  MTBarcodeDatabar.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodeDatabar.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeDatabar

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeDatabar type];
        self.name = @"Databar";
        self.has2dComponent = YES;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeRss14;
}

- (void)loadSampleData {
    self.input = @"6660000000001";
    self.primaryData = @"";
}

@end
