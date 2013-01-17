//
//  MTFont.h
//  Reports
//
//  Created by Michael Thomason on 1/1/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const MTFontFamilyAmericanTypewriter;
extern NSString * const MTFontFamilyArial;
extern NSString * const MTFontFamilyCourierNew;
extern NSString * const MTFontFamilyCourier;
extern NSString * const MTFontFamilyGeorgia;
extern NSString * const MTFontFamilyHelvetica;
extern NSString * const MTFontFamilyHelveticaNeue;
extern NSString * const MTFontFamilyTimesNewRoman;
extern NSString * const MTFontFamilyTrebuchet;
extern NSString * const MTFontFamilyVerdana;
extern NSString * const MTFontFamilyZapfino;

@interface MTFont : NSObject

@property (assign) CGFloat pointSize;

+ (id)fontWithFamilyName:(NSString *)familyName;
- (id)initWithFamilyName:(NSString *)familyName;
- (id)initWithFamilyName:(NSString *)familyName andPointSize:(CGFloat)pointSize;

- (UIFont *)font;
- (UIFont *)italicFont;
- (UIFont *)boldFont;
- (UIFont *)boldItalicFont;
- (NSString *)name;

+ (NSArray *)familyNames;

+ (NSString *)defaultFamily;
+ (CGFloat)defaultSize;

@end