//
//  MADElementMigrationPolicy.m
//  MAD Designer
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADElementMigrationPolicy.h"
#import <UIKit/UIGeometry.h>
#import <UIKit/UIColor.h>
#import <MAD/MADAlignment.h>
#import <MAD/MADCurrencyFormatter.h>
#import <MADCocoaExtensions/MADBorderStyle.h>
#import <MADCocoaExtensions/MADMargin.h>
#import <MADCocoaExtensions/MADPadding.h>
#import <MADCocoaExtensions/MADTextStyle.h>

@implementation MADElementMigrationPolicy

- (NSValue *)migrateValueFromPointX:(NSNumber *)x pointY:(NSNumber *)y {
    CGPoint origin = CGPointMake(x.floatValue, y.floatValue);
    return [NSValue valueWithCGPoint:origin];
}

- (MADAlignment *)migrateValueFromAlignmentHorizontal:(NSNumber *)horizontal
                                        vertical:(NSNumber *)vertical {
    int16_t h, v;
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)horizontal, kCFNumberSInt16Type, &h);
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)vertical, kCFNumberSInt16Type, &v);
    MADAlignment *a = [[MADAlignment alloc] initWithHorizontal:h
                                                      vertical:v];
    return a;
}

- (UIColor *)migrateColorFromData:(NSData *)colorData {
    return [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
}

- (MADMargin *)migrateValueFromMarginLeft:(NSNumber *)left
                                    right:(NSNumber *)right
                                      top:(NSNumber *)top
                                   bottom:(NSNumber *)bottom {
    id result = [[MADMargin alloc] initWithLeft: left.doubleValue
                                          right: right.doubleValue
                                            top: top.doubleValue
                                         bottom: bottom.doubleValue];
    return result;
}

- (MADPadding *)migrateValueFromPaddingLeft:(NSNumber *)left
                                      right:(NSNumber *)right
                                        top:(NSNumber *)top
                                     bottom:(NSNumber *)bottom {
    id padding = [[MADPadding alloc] initWithLeft: left.doubleValue
                                            right: right.doubleValue
                                              top: top.doubleValue
                                           bottom: bottom.doubleValue];
    return padding;
}

- (MADTextStyle *)migrateTextStyleBold:(NSNumber *)bold
                         strikethrough:(NSNumber *)strikethrough
                                italic:(NSNumber *)italic
                             underline:(NSNumber *)underline {
    id textStyle = [[MADTextStyle alloc] initWithBold: bold.boolValue
                                               italic: italic.boolValue
                                            underline: underline.boolValue
                                        strikethrough: strikethrough.boolValue];
    return textStyle;
}

- (NSValue *)migrateValueFromSizeWidth:(NSNumber *)width height:(NSNumber *)height {
    CGSize s = CGSizeMake(width.floatValue, height.floatValue);
    return [NSValue valueWithCGSize:s];
}

- (MADBorderStyle *)migrateValueFromBorderHeightBottom:(NSNumber *)heightBottom
                                             heightTop:(NSNumber *)heightTop
                                             widthLeft:(NSNumber *)widthLeft
                                            widthRight:(NSNumber *)widthRight
                                           styleBottom:(NSNumber *)styleBottom
                                              styleTop:(NSNumber *)styleTop
                                             styleLeft:(NSNumber *)styleLeft
                                            styleRight:(NSNumber *)styleRight {
    if (heightBottom == nil ||
        heightTop == nil ||
        widthLeft == nil ||
        widthRight == nil ||
        styleBottom == nil ||
        styleTop == nil ||
        styleRight == nil ||
        styleBottom == nil) return nil;
    
    int16_t ls, rs, ts, bs;

    CFNumberGetValue((__bridge CFNumberRef _Nonnull)styleLeft, kCFNumberSInt16Type, &ls);
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)styleRight, kCFNumberSInt16Type, &rs);
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)styleTop, kCFNumberSInt16Type, &ts);
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)styleBottom, kCFNumberSInt16Type, &bs);

    id style = [[MADBorderStyle alloc] initWithLeft: widthLeft.doubleValue
                                              right: widthRight.doubleValue
                                                top: heightTop.doubleValue
                                             bottom: heightBottom.doubleValue
                                          leftStyle: ls
                                         rightStyle: rs
                                           topStyle: ts
                                        bottomStyle: bs];
    
    return style;
}

- (MADCurrencyFormatter *)migrateCurrencyFormatterForCurrencyEnabled:(NSNumber *)enabled
                                                              locale:(NSString *)locale
                                                        decimalCount:(NSNumber *)decimalCount {
    MADCurrencyFormatter *currency;
    currency = [[MADCurrencyFormatter alloc] init];
    currency.enabled = [enabled boolValue];
    currency.decimalCount = [decimalCount integerValue];
    currency.locale = [NSLocale currentLocale];
    return currency;
}

- (NSString *)migrateValueFromMySQLDatabaseName:(NSString *)mySQLDBName
                                      tdsDBName:(NSString *)tdsDBName {
    NSString *databaseName;
    if (mySQLDBName.length > 0)
        databaseName = mySQLDBName.copy;
    else if (tdsDBName.length > 0)
        databaseName = tdsDBName.copy;

    return databaseName;
}

- (NSString *)migrateStringNotNullOrEmpty:(NSString *)s1
                                  string2:(NSString *)s2 {
    return s1.length > 0 ? s1 : s2;
}

- (NSNumber *)migrateValueInt64NotZero:(NSNumber *)v1
                                value2:(NSNumber *)v2 {
    return [v1 isEqualToNumber: @0] ? v2 : v1;
    
}

@end
