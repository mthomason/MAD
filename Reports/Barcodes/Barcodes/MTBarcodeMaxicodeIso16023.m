//
//  MTBarcodeMaxicodeIso16023.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeMaxicodeIso16023.h"

@interface MTBarcode ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, retain, readwrite) NSString *detailsSegueIdentifer;
@property (nonatomic, retain, readwrite) NSString *primaryData;

@property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
@property (nonatomic, assign, readwrite) BOOL has2dComponent;
@property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@property (nonatomic, assign, readwrite) NSInteger option2;

@end

@implementation MTBarcodeMaxicodeIso16023

- (id)init {
    self = [super init];
    if (self) {
        
        [self setBarcodeType:[MTBarcodeMaxicodeIso16023 type]];
        [self setDetailsSegueIdentifer:@"MTIdentiferSegueBarcodeExtrasMaxicode"];
        [self setName: @"Maxicode (ISO 16023)"];
        [self setHas2dComponent: NO];
        [self setHasOptionalInput: YES];
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeMaxicode;
}

- (void)setPrimaryData:(NSString *)primaryData {

}

@end
