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

#import "MTFont.h"

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

@interface MTFont()

@property (nonatomic, strong) NSString *familyName;
@property (nonatomic, assign) BOOL bold;
@property (nonatomic, assign) BOOL italic;

@end

@implementation MTFont

+ (NSArray *)familyNames {
    static NSArray *familyNames;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        familyNames = @[MTFontFamilyAmericanTypewriter, MTFontFamilyArial, MTFontFamilyCourierNew, MTFontFamilyCourier, MTFontFamilyGeorgia, MTFontFamilyHelvetica, MTFontFamilyHelveticaNeue, MTFontFamilyTimesNewRoman, MTFontFamilyTrebuchet, MTFontFamilyVerdana, MTFontFamilyZapfino];
    });
    return familyNames;
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
    static NSDictionary *fontNamesByFamilyNames;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fontNamesByFamilyNames = @{
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
    });
    
    return fontNamesByFamilyNames;
}

+ (NSDictionary *)americanTypewriter {
    static NSDictionary *americanTypewriter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        americanTypewriter = @{
                               MTFontNormal :          @"AmericanTypewriter",
                               MTFontBold :            @"AmericanTypewriter-Bold",
                               MTFontCondensed :       @"AmericanTypewriter-Condensed",
                               MTFontCondensedBold :   @"AmericanTypewriter-CondensedBold",
                               MTFontCondensedLight :  @"AmericanTypewriter-CondensedLight",
                               MTFontLight :           @"AmericanTypewriter-Light"
                               };
    });
    return americanTypewriter;
}

+ (NSDictionary *)arial {
    static NSDictionary *arial;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        arial = @{
                  MTFontNormal :          @"ArialMT",
                  MTFontBold :            @"Arial-BoldMT",
                  MTFontItalic :          @"Arial-ItalicMT",
                  MTFontBoldItalic :      @"Arial-BoldItalicMT",
                  };
    });
    return arial;
}

+ (NSDictionary *)courierNew {
    static NSDictionary *courierNew;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        courierNew = @{
                       MTFontNormal :          @"CourierNewPSMT",
                       MTFontBold :            @"CourierNewPS-BoldMT",
                       MTFontItalic :          @"CourierNewPS-ItalicMT",
                       MTFontBoldItalic :      @"CourierNewPS-BoldItalicMT"
                       };
    });
    return courierNew;
}

+ (NSDictionary *)courier {
    static NSDictionary *courier;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        courier = @{
                    MTFontNormal :          @"Courier",
                    MTFontBold :            @"Courier-Bold",
                    MTFontOblique :         @"Courier-Oblique",
                    MTFontBoldOblique :     @"Courier-BoldOblique",
                    };
    });
    return courier;
}

+ (NSDictionary *)georgia {
    static NSDictionary *georgia;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        georgia = @{
                    MTFontNormal :          @"Georgia",
                    MTFontBold :            @"Georgia-Bold",
                    MTFontItalic :          @"Georgia-BoldItalic",
                    MTFontBoldItalic :      @"Georgia-Italic",
                    };
    });
    return georgia;
}

+ (NSDictionary *)helvetica {
    static NSDictionary *helvetica;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helvetica = @{
                      MTFontNormal :          @"Helvetica",
                      MTFontBold :            @"Helvetica-Bold",
                      MTFontBoldOblique :     @"Helvetica-BoldOblique",
                      MTFontLight :           @"Helvetica-Light",
                      MTFontLightOblique :    @"Helvetica-LightOblique",
                      MTFontOblique :         @"Helvetica-Oblique",
                      MTFontItalic :          @"Helvetica-Oblique",
                      MTFontBoldItalic :      @"Helvetica-BoldOblique"
                      };
    });
    return helvetica;
}

+ (NSDictionary *)helveticaNeue {
    static NSDictionary *helveticaNeue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helveticaNeue = @{
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
                          };;
    });
    return helveticaNeue;
}

+ (NSDictionary *)timesNewRoman {
    static NSDictionary *timesNewRoman;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timesNewRoman = @{
                          MTFontNormal :          @"TimesNewRomanPSMT",
                          MTFontBold :            @"TimesNewRomanPS-BoldMT",
                          MTFontItalic :          @"TimesNewRomanPS-ItalicMT",
                          MTFontBoldItalic :      @"TimesNewRomanPS-BoldItalicMT",
                          };
    });
    return timesNewRoman;
}

+ (NSDictionary *)trebuchet {
    static NSDictionary *trebuchet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        trebuchet = @{
                      MTFontNormal :          @"TrebuchetMS",
                      MTFontBold :            @"TrebuchetMS-Bold",
                      MTFontItalic :          @"TrebuchetMS-Italic",
                      MTFontBoldItalic :      @"Trebuchet-BoldItalic",
                      };
    });
    return trebuchet;
}

+ (NSDictionary *)verdana {
    static NSDictionary *verdana;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        verdana = @{
                    MTFontNormal :          @"Verdana",
                    MTFontBold :            @"Verdana-Bold",
                    MTFontItalic :          @"Verdana-Italic",
                    MTFontBoldItalic :      @"Verdana-BoldItalic",
                    };
    });
    return verdana;
}

+ (NSDictionary *)zapfino {
    static NSDictionary *zapfino;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        zapfino = @{
                    MTFontNormal :          @"Zapfino"
                    };
    });
    return zapfino;
}

+ (NSString *)defaultFamily {
    return MTFontFamilyHelveticaNeue;
}

+ (CGFloat)defaultSize {
    return 9.0000f;
}

+ (id)fontWithFamilyName:(NSString *)familyName {
    if ([familyName length] == 0) {
        familyName = MTFontFamilyHelveticaNeue;
    }
    MTFont *font = [[MTFont alloc] initWithFamilyName:familyName];
    return font;
}

- (id)init {
    return [self initWithFamilyName:[MTFont defaultFamily]];
}

- (id)initWithFamilyName:(NSString *)familyName {
    return [self initWithFamilyName:familyName andPointSize:[MTFont defaultSize]];
}

- (id)initWithFamilyName:(NSString *)familyName andPointSize:(CGFloat)pointSize {
    self = [super init];
    if (self) {
        [self setFamilyName:familyName];
        [self setPointSize:pointSize];
    }
    return self;
}

- (id)initWithFamilyName:(NSString *)familyName andPointSize:(CGFloat)pointSize isBold:(BOOL)bold isItalic:(BOOL)italic {
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
    NSDictionary *fontNames = [MTFont fontNamesForFamilyName:[self familyName]];
    NSString *fontName = [fontNames objectForKey: MTFontNormal];
    if ([fontName length] == 0) {
        fontName = [fontNames objectForKey: MTFontNormal];
    }
    CTFontRef result = CTFontCreateWithName((__bridge CFStringRef)fontName, [self pointSize], NULL);
    return result;
}

- (UIFont *)standardFont {
    NSDictionary *fontNames = [MTFont fontNamesForFamilyName:[self familyName]];
    NSString *fontName = [fontNames objectForKey: MTFontNormal];
    UIFont *result = nil;
    if ([fontName length] == 0) {
        fontName = [fontNames objectForKey: MTFontNormal];
    }
    result = [UIFont fontWithName:fontName size:[self pointSize]];
    return result;
}

- (CTFontRef)italicCoreTextFont {
    NSDictionary *fontNames = [MTFont fontNamesForFamilyName:[self familyName]];
    NSString *fontName = [fontNames objectForKey: MTFontItalic];
    if ([fontName length] == 0) {
        fontName = [fontNames objectForKey: MTFontNormal];
    }
    CTFontRef result = CTFontCreateWithName((__bridge CFStringRef)fontName, [self pointSize], NULL);
    return result;
}

- (UIFont *)italicFont {
    NSDictionary *fontNames = [MTFont fontNamesForFamilyName:[self familyName]];
    NSString *fontName = [fontNames objectForKey: MTFontItalic];
    UIFont *result = nil;
    if ([fontName length] == 0) {
        fontName = [fontNames objectForKey: MTFontNormal];
    }
    result = [UIFont fontWithName:fontName size:[self pointSize]];
    return result;
}

- (CTFontRef)boldCoreTextFont {
    NSDictionary *fontNames = [MTFont fontNamesForFamilyName:[self familyName]];
    NSString *fontName = [fontNames objectForKey: MTFontBold];
    if ([fontName length] == 0) {
        fontName = [fontNames objectForKey: MTFontNormal];
    }
    CTFontRef result = CTFontCreateWithName((__bridge CFStringRef)fontName, [self pointSize], NULL);
    return result;
}

- (UIFont *)boldFont {
    NSDictionary *fontNames = [MTFont fontNamesForFamilyName:[self familyName]];
    NSString *fontName = [fontNames objectForKey: MTFontBold];
    UIFont *result = nil;
    if ([fontName length] == 0) {
        fontName = [fontNames objectForKey: MTFontNormal];
    }
    result = [UIFont fontWithName:fontName size:[self pointSize]];
    return result;
}


- (CTFontRef)boldItalicCoreTextFont {
    NSDictionary *fontNames = [MTFont fontNamesForFamilyName:[self familyName]];
    NSString *fontName = [fontNames objectForKey: MTFontBoldItalic];
    if ([fontName length] == 0) {
        fontName = [fontNames objectForKey: MTFontNormal];
    }
    CTFontRef result = CTFontCreateWithName((__bridge CFStringRef)fontName, [self pointSize], NULL);
    return result;
}

- (UIFont *)boldItalicFont {
    NSDictionary *fontNames = [MTFont fontNamesForFamilyName:[self familyName]];
    NSString *fontName = [fontNames objectForKey: MTFontBoldItalic];
    UIFont *result = nil;
    if ([fontName length] == 0) {
        fontName = [fontNames objectForKey: MTFontNormal];
    }
    result = [UIFont fontWithName:fontName size:[self pointSize]];
    return result;
}

- (NSString *)name {
    return [self familyName];
}

@end
