//
//  MTFont.h
//  Reports
//
//  Created by Michael Thomason on 1/1/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADFont_h
#define Reports_MADFont_h

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>

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

@interface MADFont : NSObject

+ (instancetype)fontWithFamilyName:(NSString *)familyName NS_RETURNS_RETAINED;
- (instancetype)init;
- (instancetype)initWithFamilyName:(NSString *)familyName;
- (instancetype)initWithFamilyName:(NSString *)familyName andPointSize:(CGFloat)pointSize NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFamilyName:(NSString *)familyName andPointSize:(CGFloat)pointSize isBold:(BOOL)bold isItalic:(BOOL)italic NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, readonly) NSString *familyName;
@property (nonatomic, assign) CGFloat pointSize;

- (UIFont *)font;
- (CTFontRef)coreTextFont;
- (UIFont *)standardFont;
- (UIFont *)italicFont;
- (UIFont *)boldFont;
- (UIFont *)boldItalicFont;

+ (NSArray *)familyNames;

+ (NSString *)defaultFamily;
+ (CGFloat)defaultSize;

@end

#endif
