//
//  MTPaper.m
//  Reports
//
//  Created by Michael Thomason on 5/28/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaper.h"

#import <MADCocoaExtensions/CGGeometry+Extras.h>

static inline CGRect CGRectBoundsForSize(CGSize size) {
	return CGRectMake(CGPointZero.x, CGPointZero.y, size.width, size.height);
}

static inline CGSize CGSizePaperLetter(void) {
	return CGSizeMake(fCGPointsForInches(8.5000f), fCGPointsForInches(11.0000f));
}

static inline CGSize CGSizePaperGovernmentLetter(void) {
	return CGSizeMake(fCGPointsForInches(8.5000f), fCGPointsForInches(10.5000f));
}

static inline CGSize CGSizePaperLegal(void) {
	return CGSizeMake(fCGPointsForInches(8.5000f), fCGPointsForInches(14.0000f));
}

static inline CGSize CGSizePaperA0(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(841.0000f), CGFloatPointsForMillimeters(1189.0000f));
}

static inline CGSize CGSizePaperA1(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(594.0000f), CGFloatPointsForMillimeters(841.0000f));
}

static inline CGSize CGSizePaperA2(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(420.0000f), CGFloatPointsForMillimeters(594.0000f));
}

static inline CGSize CGSizePaperA3(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(297.0000f), CGFloatPointsForMillimeters(420.0000f));
}

static inline CGSize CGSizePaperA4(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(210.0000f), CGFloatPointsForMillimeters(297.0000f));
}

static inline CGSize CGSizePaperA5(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(148.0000f), CGFloatPointsForMillimeters(210.0000f));
}

static inline CGSize CGSizePaperA6(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(105.0000f), CGFloatPointsForMillimeters(148.0000f));
}

static inline CGSize CGSizePaperA7(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(74.0000f), CGFloatPointsForMillimeters(105.0000f));
}

static inline CGSize CGSizePaperA8(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(52.0000f), CGFloatPointsForMillimeters(74.0000f));
}

static inline CGSize CGSizePaperA9(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(37.0000f), CGFloatPointsForMillimeters(52.0000f));
}

static inline CGSize CGSizePaperA10(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(26.0000f), CGFloatPointsForMillimeters(37.0000f));
}

static inline CGSize CGSizePaperB0(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(1000.0000f), CGFloatPointsForMillimeters(1414.0000f));
}

static inline CGSize CGSizePaperB1(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(707.0000f), CGFloatPointsForMillimeters(1000.0000f));
}

static inline CGSize CGSizePaperB2(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(500.0000f), CGFloatPointsForMillimeters(707.0000f));
}

static inline CGSize CGSizePaperB3(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(353.0000f), CGFloatPointsForMillimeters(500.0000f));
}

static inline CGSize CGSizePaperB4(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(250.0000f), CGFloatPointsForMillimeters(353.0000f));
}

static inline CGSize CGSizePaperB5(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(176.0000f), CGFloatPointsForMillimeters(250.0000f));
}

static inline CGSize CGSizePaperB6(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(125.0000f), CGFloatPointsForMillimeters(176.0000f));
}

static inline CGSize CGSizePaperB7(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(88.0000f), CGFloatPointsForMillimeters(125.0000f));
}

static inline CGSize CGSizePaperB8(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(62.0000f), CGFloatPointsForMillimeters(88.0000f));
}

static inline CGSize CGSizePaperB9(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(44.0000f), CGFloatPointsForMillimeters(62.0000f));
}

static inline CGSize CGSizePaperB10(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(31.0000f), CGFloatPointsForMillimeters(44.0000f));
}

static inline CGSize CGSizePaperC0(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(917.0000f), CGFloatPointsForMillimeters(1297.0000f));
}

static inline CGSize CGSizePaperC1(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(648.0000f), CGFloatPointsForMillimeters(917.0000f));
}

static inline CGSize CGSizePaperC2(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(458.0000f), CGFloatPointsForMillimeters(648.0000f));
}

static inline CGSize CGSizePaperC3(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(324.0000f), CGFloatPointsForMillimeters(458.0000f));
}

static inline CGSize CGSizePaperC4(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(229.0000f), CGFloatPointsForMillimeters(324.0000f));
}

static inline CGSize CGSizePaperC5(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(162.0000f), CGFloatPointsForMillimeters(229.0000f));
}

static inline CGSize CGSizePaperC6(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(114.0000f), CGFloatPointsForMillimeters(162.0000f));
}

static inline CGSize CGSizePaperC7(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(81.0000f), CGFloatPointsForMillimeters(114.0000f));
}

static inline CGSize CGSizePaperC8(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(57.0000f), CGFloatPointsForMillimeters(81.0000f));
}

static inline CGSize CGSizePaperC9(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(40.0000f), CGFloatPointsForMillimeters(57.0000f));
}

static inline CGSize CGSizePaperC10(void) {
	return CGSizeMake(CGFloatPointsForMillimeters(28.0000f), CGFloatPointsForMillimeters(40.0000f));
}

// The sizes a paper type answers.  The values are the DMPAPER-style ids that
// .mad documents persist, so the enum itself must not move; this table maps
// each one to its size function, in enum order.
typedef struct {
	MTPaperType paperType;
	CGSize (*sizeFunction)(void);
} MTPaperSizeEntry;

static const MTPaperSizeEntry kMTPaperSizeTable[] = {
	{ MTPaperTypeLetter,		   CGSizePaperLetter },
	{ MTPaperTypeGovernmentLetter, CGSizePaperGovernmentLetter },
	// Government legal prints at legal size, and always has.
	{ MTPaperTypeGovernmentLegal,  CGSizePaperLegal },
	{ MTPaperTypeLegal,			   CGSizePaperLegal },
	{ MTPaperTypeA0,			   CGSizePaperA0 },
	{ MTPaperTypeA1,			   CGSizePaperA1 },
	{ MTPaperTypeA2,			   CGSizePaperA2 },
	{ MTPaperTypeA3,			   CGSizePaperA3 },
	{ MTPaperTypeA4,			   CGSizePaperA4 },
	{ MTPaperTypeA5,			   CGSizePaperA5 },
	{ MTPaperTypeA6,			   CGSizePaperA6 },
	{ MTPaperTypeA7,			   CGSizePaperA7 },
	{ MTPaperTypeA8,			   CGSizePaperA8 },
	{ MTPaperTypeA9,			   CGSizePaperA9 },
	{ MTPaperTypeA10,			   CGSizePaperA10 },
	{ MTPaperTypeB0,			   CGSizePaperB0 },
	{ MTPaperTypeB1,			   CGSizePaperB1 },
	{ MTPaperTypeB2,			   CGSizePaperB2 },
	{ MTPaperTypeB3,			   CGSizePaperB3 },
	{ MTPaperTypeB4,			   CGSizePaperB4 },
	{ MTPaperTypeB5,			   CGSizePaperB5 },
	{ MTPaperTypeB6,			   CGSizePaperB6 },
	{ MTPaperTypeB7,			   CGSizePaperB7 },
	{ MTPaperTypeB8,			   CGSizePaperB8 },
	{ MTPaperTypeB9,			   CGSizePaperB9 },
	{ MTPaperTypeB10,			   CGSizePaperB10 },
	{ MTPaperTypeC0,			   CGSizePaperC0 },
	{ MTPaperTypeC1,			   CGSizePaperC1 },
	{ MTPaperTypeC2,			   CGSizePaperC2 },
	{ MTPaperTypeC3,			   CGSizePaperC3 },
	{ MTPaperTypeC4,			   CGSizePaperC4 },
	{ MTPaperTypeC5,			   CGSizePaperC5 },
	{ MTPaperTypeC6,			   CGSizePaperC6 },
	{ MTPaperTypeC7,			   CGSizePaperC7 },
	{ MTPaperTypeC8,			   CGSizePaperC8 },
	{ MTPaperTypeC9,			   CGSizePaperC9 },
	{ MTPaperTypeC10,			   CGSizePaperC10 },
};

static inline CGSize MTPaperSizeForType(MTPaperType papertype) {
	for (NSUInteger i = 0; i < sizeof(kMTPaperSizeTable) / sizeof(kMTPaperSizeTable[0]); ++i) {
		if (kMTPaperSizeTable[i].paperType == papertype) {
			return kMTPaperSizeTable[i].sizeFunction();
		}
	}
	return CGSizePaperLetter();
}

static inline BOOL MTPaperTypeIsKnown(MTPaperType papertype) {
	for (NSUInteger i = 0; i < sizeof(kMTPaperSizeTable) / sizeof(kMTPaperSizeTable[0]); ++i) {
		if (kMTPaperSizeTable[i].paperType == papertype) {
			return YES;
		}
	}
	return NO;
}

@interface MTPaper ()

	- (instancetype)init;

@end

@implementation MTPaper

- (instancetype)init {
	return [self initWithType:MTPaperTypeLetter];
}

+ (CGSize)sizeForType:(MTPaperType)papertype {
	return MTPaperSizeForType(papertype);
}

+ (NSArray<NSNumber *> *)standardPaperTypes {
	return @[
		@(MTPaperTypeLetter),
		@(MTPaperTypeLegal),
		@(MTPaperTypeGovernmentLetter),
		@(MTPaperTypeA4),
		@(MTPaperTypeA3),
		@(MTPaperTypeA5),
		@(MTPaperTypeB4),
		@(MTPaperTypeB5),
	];
}

+ (NSString *)displayNameForPaperType:(MTPaperType)papertype {
	switch (papertype) {
		case MTPaperTypeLetter:				return @"US Letter (8.5 × 11 in)";
		case MTPaperTypeLegal:				return @"US Legal (8.5 × 14 in)";
		case MTPaperTypeGovernmentLetter:	return @"Government Letter (8.0 × 10.5 in)";
		case MTPaperTypeGovernmentLegal:	return @"Government Legal (8.5 × 13 in)";
		case MTPaperTypeA3:					return @"A3 (297 × 420 mm)";
		case MTPaperTypeA4:					return @"A4 (210 × 297 mm)";
		case MTPaperTypeA5:					return @"A5 (148 × 210 mm)";
		case MTPaperTypeB4:					return @"B4 (250 × 353 mm)";
		case MTPaperTypeB5:					return @"B5 (176 × 250 mm)";
		default: {
			CGSize s = MTPaperSizeForType(papertype);
			return [NSString stringWithFormat:@"Paper (%.0f × %.0f pt)", s.width, s.height];
		}
	}
}

+ (NSString *)shortDisplayNameForPaperType:(MTPaperType)papertype {
	switch (papertype) {
		case MTPaperTypeLetter:				return @"US Letter";
		case MTPaperTypeLegal:				return @"US Legal";
		case MTPaperTypeGovernmentLetter:	return @"Gov Letter";
		case MTPaperTypeGovernmentLegal:	return @"Gov Legal";
		case MTPaperTypeA3:					return @"A3";
		case MTPaperTypeA4:					return @"A4";
		case MTPaperTypeA5:					return @"A5";
		case MTPaperTypeB4:					return @"B4";
		case MTPaperTypeB5:					return @"B5";
		default:							return @"US Letter";
	}
}

- (instancetype)initWithType:(MTPaperType)papertype {
	if (self = [super init]) {
		_paperType = MTPaperTypeIsKnown(papertype) ? papertype : MTPaperTypeLetter;
	}
	return self;
}

- (CGSize)paperSize {
	return MTPaperSizeForType(self.paperType);
}

- (CGRect)bounds {
	return CGRectBoundsForSize(self.paperSize);
}

- (NSString *)displayName {
	return [MTPaper displayNameForPaperType:self.paperType];
}

- (NSString *)shortDisplayName {
	return [MTPaper shortDisplayNameForPaperType:self.paperType];
}

@end
