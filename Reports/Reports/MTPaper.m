//
//  MTPaper.m
//  Reports
//
//  Created by Michael Thomason on 5/28/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTPaper.h"

@implementation MTPaper

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
