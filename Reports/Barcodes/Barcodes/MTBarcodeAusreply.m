//
//  MTBarcodeAusreply.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeAusreply.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeAusreply

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeAusreply type]];
        [self setName: @"Australia Post Reply-Paid"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: NO];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeAusreply;
}

- (void)initSampleData {
    [self setInput:              @"39549554"];
    [self setPrimaryData:        @""];
}

@end
