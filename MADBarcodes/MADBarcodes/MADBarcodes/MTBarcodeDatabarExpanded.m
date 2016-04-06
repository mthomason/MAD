//
//  MTBarcodeDatabarExpanded.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcodeDatabarExpanded.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodeDatabarExpanded

- (instancetype)init {

    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodeDatabarExpanded type];
        self.name = @"Databar Expanded";
        self.has2dComponent = YES;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypeRssExp;
}

- (void)initSampleData {
    [self setInput:              @"[01]98898765432106[3202]012345[15]991231"];
    [self setPrimaryData:        @""];
}


@end
