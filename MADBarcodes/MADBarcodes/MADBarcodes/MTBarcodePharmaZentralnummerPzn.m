//
//  MTBarcodePharmaZentralnummerPzn.m
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTBarcodePharmaZentralnummerPzn.h"

@interface MTBarcode ()

    @property (nonatomic, strong, readwrite) NSString *name;
    @property (nonatomic, assign, readwrite) MTBarcodeType barcodeType;
    @property (nonatomic, assign, readwrite) BOOL has2dComponent;
    @property (nonatomic, assign, readwrite) BOOL hasOptionalInput;

@end

@implementation MTBarcodePharmaZentralnummerPzn

- (instancetype)init {
    if (self = [super init]) {
        
        self.barcodeType = [MTBarcodePharmaZentralnummerPzn type];
        self.name = @"Pharma Zentralnummer (PZN)";
        self.has2dComponent = NO;
        self.hasOptionalInput = NO;
        
    }
    return self;
}

+ (MTBarcodeType)type {
    return MTBarcodeTypePzn;
}

- (void)loadSampleData {
    self.input = @"123456";
    self.primaryData = @"";
}

@end
