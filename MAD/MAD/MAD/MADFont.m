//
//  MTFont.m
//  Reports
//
//  Created by Michael Thomason on 1/1/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADFont.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <UIKit/UIFont.h>

// MARK: Keys for each type of font.
NSString * const MTFontNormal            = @"MTFontNormal";
NSString * const MTFontBold              = @"MTFontBold";
NSString * const MTFontItalic            = @"MTFontItalic";
NSString * const MTFontBoldItalic        = @"MTFontBoldItalic";
NSString * const MTFontBoldOblique       = @"MTFontBoldOblique";
NSString * const MTFontCondensed         = @"MTFontCondensed";
NSString * const MTFontCondensedBold     = @"MTFontCondensedBold";
NSString * const MTFontCondensedLight    = @"MTFontCondensedLight";
NSString * const MTFontMedium            = @"MTFontMedium";
NSString * const MTFontLight             = @"MTFontLight";
NSString * const MTFontLightOblique      = @"MTFontLightOblique";
NSString * const MTFontHeavy             = @"MTFontHeavy";
NSString * const MTFontOblique           = @"MTFontOblique";
NSString * const MTFontCondensedBlack    = @"MTFontCondensedBlack";
NSString * const MTFontLightItalic       = @"MTFontLightItalic";
NSString * const MTFontUltraLight        = @"MTFontUltraLight";
NSString * const MTFontUltraLightItalic  = @"MTFontUltraLightItalic";

NSString * const MTFontName              = @"MTFontName";

// MARK: Displayable key for each font family.
NSString * const MTFontFamilyAmericanTypewriter  = @"American Typewriter";
NSString * const MTFontFamilyArial               = @"Arial";
NSString * const MTFontFamilyCourierNew          = @"Courier New";
NSString * const MTFontFamilyCourier             = @"Courier";
NSString * const MTFontFamilyGeorgia             = @"Georgia";
NSString * const MTFontFamilyHelvetica           = @"Helvetica";
NSString * const MTFontFamilyHelveticaNeue       = @"Helvetica Neue";
NSString * const MTFontFamilyTimesNewRoman       = @"Times New Roman";
NSString * const MTFontFamilyTrebuchet           = @"Trebuchet";
NSString * const MTFontFamilyVerdana             = @"Verdana";
NSString * const MTFontFamilyZapfino             = @"Zapfino";

@interface MADFont()

@property (nonatomic, strong, readwrite) NSString *familyName;
@property (nonatomic, assign) BOOL bold;
@property (nonatomic, assign) BOOL italic;

@end

@implementation MADFont

+ (NSArray *)familyNames {
    return @[MTFontFamilyAmericanTypewriter, MTFontFamilyArial, MTFontFamilyCourierNew, MTFontFamilyCourier, MTFontFamilyGeorgia, MTFontFamilyHelvetica, MTFontFamilyHelveticaNeue, MTFontFamilyTimesNewRoman, MTFontFamilyTrebuchet, MTFontFamilyVerdana, MTFontFamilyZapfino];
}

+ (NSDictionary *)fontNamesForFamilyName:(NSString *)familyName {
    NSDictionary *result;
    if ([familyName isEqualToString:MTFontFamilyAmericanTypewriter]) {
        result = [self americanTypewriter];
    } else if ([familyName isEqualToString:MTFontFamilyArial]) {
        result = [self arial];
    } else if ([familyName isEqualToString:MTFontFamilyCourierNew]) {
        result = [self courierNew];
    } else if ([familyName isEqualToString:MTFontFamilyCourier]) {
        result = [self courier];
    } else if ([familyName isEqualToString:MTFontFamilyGeorgia]) {
        result = [self georgia];
    } else if ([familyName isEqualToString:MTFontFamilyHelvetica]) {
        result = [self helvetica];
    } else if ([familyName isEqualToString:MTFontFamilyHelveticaNeue]) {
        result = [self helveticaNeue];
    } else if ([familyName isEqualToString:MTFontFamilyTimesNewRoman]) {
        result = [self timesNewRoman];
    } else if ([familyName isEqualToString:MTFontFamilyTrebuchet]) {
        result = [self trebuchet];
    } else if ([familyName isEqualToString:MTFontFamilyVerdana]) {
        result = [self verdana];
    } else if ([familyName isEqualToString:MTFontFamilyZapfino]) {
        result = [self zapfino];
    } else {
        result = [self helveticaNeue];
    }
    return result;
}

+ (NSDictionary *)fontNamesByFamilyNames {
    return @{
             MTFontFamilyAmericanTypewriter :    [self americanTypewriter],
             MTFontFamilyArial :                 [self arial],
             MTFontFamilyCourier :               [self courier],
             MTFontFamilyCourierNew :            [self courierNew],
             MTFontFamilyGeorgia :               [self georgia],
             MTFontFamilyHelvetica :             [self helvetica],
             MTFontFamilyHelveticaNeue :         [self helveticaNeue],
             MTFontFamilyTimesNewRoman :         [self timesNewRoman],
             MTFontFamilyTrebuchet :             [self trebuchet],
             MTFontFamilyVerdana :               [self verdana],
             MTFontFamilyZapfino :               [self zapfino],
             };
}

+ (NSDictionary *)americanTypewriter {
    return @{
             MTFontNormal :          @"AmericanTypewriter",
             MTFontBold :            @"AmericanTypewriter-Bold",
             MTFontCondensed :       @"AmericanTypewriter-Condensed",
             MTFontCondensedBold :   @"AmericanTypewriter-CondensedBold",
             MTFontCondensedLight :  @"AmericanTypewriter-CondensedLight",
             MTFontLight :           @"AmericanTypewriter-Light"
             };
}

+ (NSDictionary *)arial {
    return @{
             MTFontNormal :          @"ArialMT",
             MTFontBold :            @"Arial-BoldMT",
             MTFontItalic :          @"Arial-ItalicMT",
             MTFontBoldItalic :      @"Arial-BoldItalicMT",
             };
}

+ (NSDictionary *)courierNew {
    return @{
             MTFontNormal :          @"CourierNewPSMT",
             MTFontBold :            @"CourierNewPS-BoldMT",
             MTFontItalic :          @"CourierNewPS-ItalicMT",
             MTFontBoldItalic :      @"CourierNewPS-BoldItalicMT"
             };
}

+ (NSDictionary *)courier {
    return @{
             MTFontNormal :          @"Courier",
             MTFontBold :            @"Courier-Bold",
             MTFontOblique :         @"Courier-Oblique",
             MTFontBoldOblique :     @"Courier-BoldOblique",
             };
}

+ (NSDictionary *)georgia {
    return @{
             MTFontNormal :          @"Georgia",
             MTFontBold :            @"Georgia-Bold",
             MTFontItalic :          @"Georgia-BoldItalic",
             MTFontBoldItalic :      @"Georgia-Italic",
             };
}

+ (NSDictionary *)helvetica {
    return @{
             MTFontNormal :          @"Helvetica",
             MTFontBold :            @"Helvetica-Bold",
             MTFontBoldOblique :     @"Helvetica-BoldOblique",
             MTFontLight :           @"Helvetica-Light",
             MTFontLightOblique :    @"Helvetica-LightOblique",
             MTFontOblique :         @"Helvetica-Oblique",
             MTFontItalic :          @"Helvetica-Oblique",
             MTFontBoldItalic :      @"Helvetica-BoldOblique"
             };
}

+ (NSDictionary *)helveticaNeue {
    return @{
             MTFontNormal :          @"HelveticaNeue",
             MTFontBold :            @"HelveticaNeue-Bold",
             MTFontItalic :          @"HelveticaNeue-LightItalic",
             MTFontBoldItalic :      @"HelveticaNeue-BoldItalic",
             MTFontCondensedBold :   @"HelveticaNeue-CondensedBold",
             MTFontCondensedBlack :  @"HelveticaNeue-CondensedBlack",
             MTFontLight :           @"HelveticaNeue-Light",
             MTFontLightItalic :     @"HelveticaNeue-LightItalic",
             MTFontMedium :          @"HelveticaNeue-Medium",
             MTFontUltraLightItalic :@"HelveticaNeue-UltraLight",
             MTFontUltraLight :      @"HelveticaNeue-UltraLightItalic",
             };
}

+ (NSDictionary *)timesNewRoman {
    return @{
             MTFontNormal :          @"TimesNewRomanPSMT",
             MTFontBold :            @"TimesNewRomanPS-BoldMT",
             MTFontItalic :          @"TimesNewRomanPS-ItalicMT",
             MTFontBoldItalic :      @"TimesNewRomanPS-BoldItalicMT",
             };
}

+ (NSDictionary *)trebuchet {
    return @{
             MTFontNormal :          @"TrebuchetMS",
             MTFontBold :            @"TrebuchetMS-Bold",
             MTFontItalic :          @"TrebuchetMS-Italic",
             MTFontBoldItalic :      @"Trebuchet-BoldItalic",
             };
}

+ (NSDictionary *)verdana {
    return @{
             MTFontNormal :          @"Verdana",
             MTFontBold :            @"Verdana-Bold",
             MTFontItalic :          @"Verdana-Italic",
             MTFontBoldItalic :      @"Verdana-BoldItalic",
             };
}

+ (NSDictionary *)zapfino {
    return @{
             MTFontNormal :          @"Zapfino"
             };
}

+ (NSString *)defaultFamily {
    return MTFontFamilyHelveticaNeue;
}

+ (CGFloat)defaultSize {
    return 9.0000f;
}

+ (instancetype)fontWithFamilyName:(NSString *)familyName NS_RETURNS_RETAINED {
    if ([familyName length] == 0) {
        familyName = MTFontFamilyHelveticaNeue;
    }
    MADFont *font = [[MADFont alloc] initWithFamilyName:familyName];
    return font;
}

- (instancetype)init {
    return [self initWithFamilyName:[MADFont defaultFamily]];
}

- (instancetype)initWithFamilyName:(NSString *)familyName {
    return [self initWithFamilyName:familyName andPointSize:[MADFont defaultSize]];
}

- (instancetype)initWithFamilyName:(NSString *)familyName andPointSize:(CGFloat)pointSize {
    self = [super init];
    if (self) {
        [self setFamilyName:familyName];
        [self setPointSize:pointSize];
    }
    return self;
}

- (instancetype)initWithFamilyName:(NSString *)familyName andPointSize:(CGFloat)pointSize isBold:(BOOL)bold isItalic:(BOOL)italic {
    self = [super init];
    if (self) {
        [self setBold:bold];
        [self setItalic:italic];
        [self setFamilyName:familyName];
        [self setPointSize:pointSize];
    }
    return self;
}

- (CTFontRef)coreTextFont {
    CTFontRef result = nil;
    if ([self bold] && [self italic]) {
        result = [self boldItalicCoreTextFont];
    } else if ([self bold]) {
        result = [self boldCoreTextFont];
    } else if ([self italic]) {
        result = [self italicCoreTextFont];
    } else {
        result = [self standardCoreTextFont];
    }
    return result;
}

- (UIFont *)font {
    UIFont *result = nil;
    if ([self bold] && [self italic]) {
        result = [self boldItalicFont];
    } else if ([self bold]) {
        result = [self boldFont];
    } else if ([self italic]) {
        result = [self italicFont];
    } else {
        result = [self standardFont];
    }
    return result;
}

- (CTFontRef)standardCoreTextFont {
    NSDictionary *fontNames = [MADFont fontNamesForFamilyName:self.familyName];
    NSString *fontName = fontNames[MTFontNormal];
    if ([fontName length] == 0) {
        fontName = fontNames[MTFontNormal];
    }
    CTFontRef result = CTFontCreateWithName((__bridge CFStringRef)fontName, self.pointSize, NULL);
    return result;
}

- (UIFont *)standardFont {
    NSDictionary *fontNames = [MADFont fontNamesForFamilyName:self.familyName];
    NSString *fontName = fontNames[MTFontNormal];
    UIFont *result = nil;
    if ([fontName length] == 0) {
        fontName = fontNames[MTFontNormal];
    }
    result = [UIFont fontWithName:fontName size:self.pointSize];
    return result;
}

- (CTFontRef)italicCoreTextFont {
    NSDictionary *fontNames = [MADFont fontNamesForFamilyName:self.familyName];
    NSString *fontName = fontNames[MTFontItalic];
    if ([fontName length] == 0) {
        fontName = fontNames[MTFontNormal];
    }
    CTFontRef result = CTFontCreateWithName((__bridge CFStringRef)fontName, self.pointSize, NULL);
    return result;
}

- (UIFont *)italicFont {
    NSDictionary *fontNames = [MADFont fontNamesForFamilyName:self.familyName];
    NSString *fontName = fontNames[MTFontItalic];
    UIFont *result = nil;
    if ([fontName length] == 0) {
        fontName = fontNames[MTFontNormal];
    }
    result = [UIFont fontWithName:fontName size:self.pointSize];
    return result;
}

- (CTFontRef)boldCoreTextFont {
    NSDictionary *fontNames = [MADFont fontNamesForFamilyName:self.familyName];
    NSString *fontName = fontNames[MTFontBold];
    if ([fontName length] == 0) {
        fontName = fontNames[MTFontNormal];
    }
    CTFontRef result = CTFontCreateWithName((__bridge CFStringRef)fontName, self.pointSize, NULL);
    return result;
}

- (UIFont *)boldFont {
    NSDictionary *fontNames = [MADFont fontNamesForFamilyName:self.familyName];
    NSString *fontName = fontNames[MTFontBold];
    UIFont *result = nil;
    if ([fontName length] == 0) {
        fontName = fontNames[MTFontNormal];
    }
    result = [UIFont fontWithName:fontName size:self.pointSize];
    return result;
}


- (CTFontRef)boldItalicCoreTextFont {
    NSDictionary *fontNames = [MADFont fontNamesForFamilyName:self.familyName];
    NSString *fontName = fontNames[MTFontBoldItalic];
    if ([fontName length] == 0) {
        fontName = fontNames[MTFontNormal];
    }
    CTFontRef result = CTFontCreateWithName((__bridge CFStringRef)fontName, self.pointSize, NULL);
    return result;
}

- (UIFont *)boldItalicFont {
    NSDictionary *fontNames = [MADFont fontNamesForFamilyName:self.familyName];
    NSString *fontName = fontNames[MTFontBoldItalic];
    UIFont *result = nil;
    if ([fontName length] == 0) {
        fontName = fontNames[MTFontNormal];
    }
    result = [UIFont fontWithName:fontName size:self.pointSize];
    return result;
}

- (NSString *)name {
    return self.familyName;
}

@end
