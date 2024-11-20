//
//  MTPaper.h
//  Reports
//
//  Created by Michael Thomason on 5/28/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTPaper_h
#define Reports_MTPaper_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>

#import <MAD/MADPaperType.h>

static inline CGRect CGRectBoundsForSize(CGSize size);
static inline CGRect CGRectPaperLetter(void);

static inline CGSize CGSizePaperLetter(void);
static inline CGSize CGSizePaperGovernmentLetter(void);
static inline CGSize CGSizePaperLegal(void);
static inline CGSize CGSizePaperA0(void);
static inline CGSize CGSizePaperA1(void);
static inline CGSize CGSizePaperA2(void);
static inline CGSize CGSizePaperA3(void);
static inline CGSize CGSizePaperA4(void);
static inline CGSize CGSizePaperA5(void);
static inline CGSize CGSizePaperA6(void);
static inline CGSize CGSizePaperA7(void);
static inline CGSize CGSizePaperA8(void);
static inline CGSize CGSizePaperA9(void);
static inline CGSize CGSizePaperA10(void);

@interface MTPaper : NSObject

    - (instancetype)initWithType:(MTPaperType)papertype NS_DESIGNATED_INITIALIZER;

    @property (nonatomic, assign, readonly) MTPaperType paperType;
    @property (nonatomic, assign, readonly) CGSize paperSize;
    @property (nonatomic, assign, readonly) CGRect bounds;

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
