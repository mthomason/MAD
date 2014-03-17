//
//  MTPaper.m
//  Reports
//
//  Created by Michael Thomason on 5/28/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTPaper.h"
#import "MTPaperLegal.h"
#import "MTPaperLetter.h"
#import "MTPaperGovernmentLegal.h"
#import "MTPaperGovernmentLetter.h"
#import "MTPaperA0.h"
#import "MTPaperA1.h"
#import "MTPaperA2.h"
#import "MTPaperA3.h"
#import "MTPaperA4.h"
#import "MTPaperA5.h"
#import "MTPaperA6.h"
#import "MTPaperA7.h"
#import "MTPaperA8.h"
#import "MTPaperA9.h"
#import "MTPaperA10.h"
#import "MTPaperB0.h"
#import "MTPaperB1.h"
#import "MTPaperB2.h"
#import "MTPaperB3.h"
#import "MTPaperB4.h"
#import "MTPaperB5.h"
#import "MTPaperB6.h"
#import "MTPaperB7.h"
#import "MTPaperB8.h"
#import "MTPaperB9.h"
#import "MTPaperB10.h"
#import "MTPaperC0.h"
#import "MTPaperC1.h"
#import "MTPaperC2.h"
#import "MTPaperC3.h"
#import "MTPaperC4.h"
#import "MTPaperC5.h"
#import "MTPaperC6.h"
#import "MTPaperC7.h"
#import "MTPaperC8.h"
#import "MTPaperC9.h"
#import "MTPaperC10.h"


@implementation MTPaper

//- (id)init {
//    return [self initWithType:MTPaperLetter];
//}

- (id)initWithType:(MTPaperType)papertype {
    
    switch (papertype) {
        
        case MTPaperTypeLetter:
            self = [MTPaperLetter init];
            break;

        case MTPaperTypeLegal:
            self = [MTPaperLegal init];
            break;

        case MTPaperTypeGovernmentLetter:
            self = [MTPaperGovernemntLetter init];
            break;

        case MTPaperTypeGovernmentLegal:
            self = [MTPaperGovernemntLegal init];
            break;

        case MTPaperTypeA0:
            self = [MTPaperA0 init];
            break;

        case MTPaperTypeA1:
            self = [MTPaperA1 init];
            break;

        case MTPaperTypeA2:
            self = [MTPaperA2 init];
            break;

        case MTPaperTypeA3:
            self = [MTPaperA3 init];
            break;

        case MTPaperTypeA4:
            self = [MTPaperA4 init];
            break;

        case MTPaperTypeA5:
            self = [MTPaperA5 init];
            break;

        case MTPaperTypeA6:
            self = [MTPaperA6 init];
            break;

        case MTPaperTypeA7:
            self = [MTPaperA7 init];
            break;

        case MTPaperTypeA8:
            self = [MTPaperA8 init];
            break;

        case MTPaperTypeA9:
            self = [MTPaperA9 init];
            break;

        case MTPaperTypeA10:
            self = [MTPaperA10 init];
            break;

        case MTPaperTypeB0:
            self = [MTPaperB0 init];
            break;
            
        case MTPaperTypeB1:
            self = [MTPaperB1 init];
            break;
            
        case MTPaperTypeB2:
            self = [MTPaperB2 init];
            break;
            
        case MTPaperTypeB3:
            self = [MTPaperB3 init];
            break;
            
        case MTPaperTypeB4:
            self = [MTPaperB4 init];
            break;
            
        case MTPaperTypeB5:
            self = [MTPaperB5 init];
            break;
            
        case MTPaperTypeB6:
            self = [MTPaperB6 init];
            break;
            
        case MTPaperTypeB7:
            self = [MTPaperB7 init];
            break;
            
        case MTPaperTypeB8:
            self = [MTPaperB8 init];
            break;
            
        case MTPaperTypeB9:
            self = [MTPaperB9 init];
            break;
            
        case MTPaperTypeB10:
            self = [MTPaperB10 init];
            break;

        case MTPaperTypeC0:
            self = [MTPaperC0 init];
            break;
            
        case MTPaperTypeC1:
            self = [MTPaperC1 init];
            break;
            
        case MTPaperTypeC2:
            self = [MTPaperC2 init];
            break;
            
        case MTPaperTypeC3:
            self = [MTPaperC3 init];
            break;
            
        case MTPaperTypeC4:
            self = [MTPaperC4 init];
            break;
            
        case MTPaperTypeC5:
            self = [MTPaperC5 init];
            break;
            
        case MTPaperTypeC6:
            self = [MTPaperC6 init];
            break;
            
        case MTPaperTypeC7:
            self = [MTPaperC7 init];
            break;
            
        case MTPaperTypeC8:
            self = [MTPaperC8 init];
            break;
            
        case MTPaperTypeC9:
            self = [MTPaperC9 init];
            break;
            
        case MTPaperTypeC10:
            self = [MTPaperC10 init];
            break;

            
        default:
            break;
    }
    
    self = [super init];
    if (self) {

    }
    return self;
}

+ (CGRect)boundsForSize:(CGSize)size {
    return CGRectMake(CGPointZero.x, CGPointZero.y, size.width, size.height);
}

+ (CGRect)rectLetter {
    return [self boundsForSize:[MTPaper sizeLetter]];
}

+ (CGRect)rectGovernemntLetter {
    return [self boundsForSize:[MTPaper sizeGovernmentLetter]];
}

+ (CGRect)rectGovernmentLegal {
    return [self boundsForSize:[MTPaper sizeLegal]];
}

+ (CGSize)sizeLetter {
    return CGSizeMake(CGFloatPointsForInches(8.5000f), CGFloatPointsForInches(11.0000f));
}

+ (CGSize)sizeGovernmentLetter {
    return CGSizeMake(CGFloatPointsForInches(8.5000f), CGFloatPointsForInches(10.5000f));
}

+ (CGSize)sizeLegal {
    return CGSizeMake(CGFloatPointsForInches(8.5000f), CGFloatPointsForInches(14.0000f));
}

+ (CGSize)sizeA0 {
    return CGSizeMake(CGFloatPointsForMillimeters(841.0000f), CGFloatPointsForMillimeters(1189.0000f));
}

+ (CGSize)sizeA1 {
    return CGSizeMake(CGFloatPointsForMillimeters(594.0000f), CGFloatPointsForMillimeters(841.0000f));
}

+ (CGSize)sizeA2 {
    return CGSizeMake(CGFloatPointsForMillimeters(420.0000f), CGFloatPointsForMillimeters(594.0000f));
}

+ (CGSize)sizeA3 {
    return CGSizeMake(CGFloatPointsForMillimeters(297.0000f), CGFloatPointsForMillimeters(420.0000f));
}

+ (CGSize)sizeA4 {
    return CGSizeMake(CGFloatPointsForMillimeters(210.0000f), CGFloatPointsForMillimeters(297.0000f));
}

+ (CGSize)sizeA5 {
    return CGSizeMake(CGFloatPointsForMillimeters(148.0000f), CGFloatPointsForMillimeters(210.0000f));
}

+ (CGSize)sizeA6 {
    return CGSizeMake(CGFloatPointsForMillimeters(105.0000f), CGFloatPointsForMillimeters(148.0000f));
}

+ (CGSize)sizeA7 {
    return CGSizeMake(CGFloatPointsForMillimeters(74.0000f), CGFloatPointsForMillimeters(105.0000f));
}

+ (CGSize)sizeA8 {
    return CGSizeMake(CGFloatPointsForMillimeters(52.0000f), CGFloatPointsForMillimeters(74.0000f));
}

+ (CGSize)sizeA9 {
    return CGSizeMake(CGFloatPointsForMillimeters(37.0000f), CGFloatPointsForMillimeters(52.0000f));
}

+ (CGSize)sizeA10 {
    return CGSizeMake(CGFloatPointsForMillimeters(26.0000f), CGFloatPointsForMillimeters(37.0000f));
}

+ (CGSize)sizeB0 {
    return CGSizeMake(CGFloatPointsForMillimeters(1000.0000f), CGFloatPointsForMillimeters(1414.0000f));
}

+ (CGSize)sizeB1 {
    return CGSizeMake(CGFloatPointsForMillimeters(707.0000f), CGFloatPointsForMillimeters(1000.0000f));
}

+ (CGSize)sizeB2 {
    return CGSizeMake(CGFloatPointsForMillimeters(500.0000f), CGFloatPointsForMillimeters(707.0000f));
}

+ (CGSize)sizeB3 {
    return CGSizeMake(CGFloatPointsForMillimeters(353.0000f), CGFloatPointsForMillimeters(500.0000f));
}

+ (CGSize)sizeB4 {
    return CGSizeMake(CGFloatPointsForMillimeters(250.0000f), CGFloatPointsForMillimeters(353.0000f));
}

+ (CGSize)sizeB5 {
    return CGSizeMake(CGFloatPointsForMillimeters(176.0000f), CGFloatPointsForMillimeters(250.0000f));
}

+ (CGSize)sizeB6 {
    return CGSizeMake(CGFloatPointsForMillimeters(125.0000f), CGFloatPointsForMillimeters(176.0000f));
}

+ (CGSize)sizeB7 {
    return CGSizeMake(CGFloatPointsForMillimeters(88.0000f), CGFloatPointsForMillimeters(125.0000f));
}

+ (CGSize)sizeB8 {
    return CGSizeMake(CGFloatPointsForMillimeters(62.0000f), CGFloatPointsForMillimeters(88.0000f));
}

+ (CGSize)sizeB9 {
    return CGSizeMake(CGFloatPointsForMillimeters(44.0000f), CGFloatPointsForMillimeters(62.0000f));
}

+ (CGSize)sizeB10 {
    return CGSizeMake(CGFloatPointsForMillimeters(31.0000f), CGFloatPointsForMillimeters(44.0000f));
}

+ (CGSize)sizeC0 {
    return CGSizeMake(CGFloatPointsForMillimeters(917.0000f), CGFloatPointsForMillimeters(1297.0000f));
}

+ (CGSize)sizeC1 {
    return CGSizeMake(CGFloatPointsForMillimeters(648.0000f), CGFloatPointsForMillimeters(917.0000f));
}

+ (CGSize)sizeC2 {
    return CGSizeMake(CGFloatPointsForMillimeters(458.0000f), CGFloatPointsForMillimeters(648.0000f));
}

+ (CGSize)sizeC3 {
    return CGSizeMake(CGFloatPointsForMillimeters(324.0000f), CGFloatPointsForMillimeters(458.0000f));
}

+ (CGSize)sizeC4 {
    return CGSizeMake(CGFloatPointsForMillimeters(229.0000f), CGFloatPointsForMillimeters(324.0000f));
}

+ (CGSize)sizeC5 {
    return CGSizeMake(CGFloatPointsForMillimeters(162.0000f), CGFloatPointsForMillimeters(229.0000f));
}

+ (CGSize)sizeC6 {
    return CGSizeMake(CGFloatPointsForMillimeters(114.0000f), CGFloatPointsForMillimeters(162.0000f));
}

+ (CGSize)sizeC7 {
    return CGSizeMake(CGFloatPointsForMillimeters(81.0000f), CGFloatPointsForMillimeters(114.0000f));
}

+ (CGSize)sizeC8 {
    return CGSizeMake(CGFloatPointsForMillimeters(57.0000f), CGFloatPointsForMillimeters(81.0000f));
}

+ (CGSize)sizeC9 {
    return CGSizeMake(CGFloatPointsForMillimeters(40.0000f), CGFloatPointsForMillimeters(57.0000f));
}

+ (CGSize)sizeC10 {
    return CGSizeMake(CGFloatPointsForMillimeters(28.0000f), CGFloatPointsForMillimeters(40.0000f));
}

@end
