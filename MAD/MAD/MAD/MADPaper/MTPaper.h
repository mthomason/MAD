//
//  MTPaper.h
//  Reports
//
//  Created by Michael Thomason on 5/28/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTPaper_h
#define Reports_MTPaper_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

typedef NS_ENUM(unsigned short, MTPaperType) {
    MTPaperTypeLetter = 2,
    MTPaperTypeGovernmentLetter = 3,
    MTPaperTypeGovernmentLegal = 5,
    MTPaperTypeLegal = 7,
    MTPaperTypeA0 = 11,
    MTPaperTypeA1 = 13,
    MTPaperTypeA2 = 17,
    MTPaperTypeA3 = 18,
    MTPaperTypeA4 = 19,
    MTPaperTypeA5 = 20,
    MTPaperTypeA6 = 21,
    MTPaperTypeA7 = 22,
    MTPaperTypeA8 = 23,
    MTPaperTypeA9 = 24,
    MTPaperTypeA10 = 25,
    MTPaperTypeB0 = 26,
    MTPaperTypeB1 = 35,
    MTPaperTypeB2 = 45,
    MTPaperTypeB3 = 55,
    MTPaperTypeB4 = 65,
    MTPaperTypeB5 = 75,
    MTPaperTypeB6 = 85,
    MTPaperTypeB7 = 95,
    MTPaperTypeB8 = 155,
    MTPaperTypeB9 = 255,
    MTPaperTypeB10 = 355,
    MTPaperTypeC0 = 405,
    MTPaperTypeC1 = 455,
    MTPaperTypeC2 = 555,
    MTPaperTypeC3 = 655,
    MTPaperTypeC4 = 755,
    MTPaperTypeC5 = 855,
    MTPaperTypeC6 = 955,
    MTPaperTypeC7 = 1055,
    MTPaperTypeC8 = 1155,
    MTPaperTypeC9 = 1255,
    MTPaperTypeC10 = 1355,
};

@interface MTPaper : NSObject

- (instancetype)initWithType:(MTPaperType)papertype NS_DESIGNATED_INITIALIZER;

@property (nonatomic, assign, readonly) MTPaperType paperType;
@property (nonatomic, assign, readonly) CGSize paperSize;

+ (MTPaperType)type;
+ (CGSize)size;

+ (CGRect)rectLetter;
+ (CGRect)rectGovernemntLetter;
+ (CGRect)rectGovernmentLegal;
+ (CGSize)sizeLetter;
+ (CGSize)sizeGovernmentLetter;
+ (CGSize)sizeGovernmentLegal;
+ (CGSize)sizeLegal;
+ (CGSize)sizeA0;
+ (CGSize)sizeA1;
+ (CGSize)sizeA2;
+ (CGSize)sizeA3;
+ (CGSize)sizeA4;
+ (CGSize)sizeA5;
+ (CGSize)sizeA6;
+ (CGSize)sizeA7;
+ (CGSize)sizeA8;
+ (CGSize)sizeA9;
+ (CGSize)sizeA10;
+ (CGSize)sizeB0;
+ (CGSize)sizeB1;
+ (CGSize)sizeB2;
+ (CGSize)sizeB3;
+ (CGSize)sizeB4;
+ (CGSize)sizeB5;
+ (CGSize)sizeB6;
+ (CGSize)sizeB7;
+ (CGSize)sizeB8;
+ (CGSize)sizeB9;
+ (CGSize)sizeB10;
+ (CGSize)sizeC0;
+ (CGSize)sizeC1;
+ (CGSize)sizeC2;
+ (CGSize)sizeC3;
+ (CGSize)sizeC4;
+ (CGSize)sizeC5;
+ (CGSize)sizeC6;
+ (CGSize)sizeC7;
+ (CGSize)sizeC8;
+ (CGSize)sizeC9;
+ (CGSize)sizeC10;

@end


@interface MTPaperGovernemntLegal : MTPaper

@end

@interface MTPaperGovernemntLetter : MTPaper

@end

#endif
