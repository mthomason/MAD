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
#import <MAD/MTAlignment.h>
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

- (NSValue *)migrateValueFromAlignmentHorizontal:(NSNumber *)horizontal
                                        vertical:(NSNumber *)vertical {
    int64_t h, v;
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)horizontal, kCFNumberSInt64Type, &v);
    MADAlignment alignment = MADAlignmentMake64(h, v);
    return [NSValue valueWithBytes:&alignment objCType:@encode(MADAlignment)];
}

- (UIColor *)migrateColorFromData:(NSData *)colorData {
    return [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
}

- (NSValue *)migrateValueFromMarginLeft:(NSNumber *)left
                                  right:(NSNumber *)right
                                    top:(NSNumber *)top
                                 bottom:(NSNumber *)bottom {
    float l, r, t, b;
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)left, kCFNumberFloatType, &l);
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)right, kCFNumberFloatType, &r);
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)top, kCFNumberFloatType, &t);
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)bottom, kCFNumberFloatType, &b);
    MADLayoutMargin m;
    m = MADLayoutMarginMake(l, r, t, b);
    return [NSValue valueWithBytes:&m objCType:@encode(MADLayoutMargin)];
}

- (NSValue *)migrateValueFromPaddingLeft:(NSNumber *)left
                                   right:(NSNumber *)right
                                     top:(NSNumber *)top
                                  bottom:(NSNumber *)bottom {
    float l, r, t, b;
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)left, kCFNumberFloatType, &l);
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)right, kCFNumberFloatType, &r);
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)top, kCFNumberFloatType, &t);
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)bottom, kCFNumberFloatType, &b);
    MADPadding p;
    p = MADPaddingMake(l, r, t, b);
    return [NSValue valueWithBytes:&p objCType:@encode(MADPadding)];
}

- (NSValue *)migrateTextStyleBold:(NSNumber *)bold
                    strikethrough:(NSNumber *)strikethrough
                           italic:(NSNumber *)italic
                        underline:(NSNumber *)underline {
    MADTextStyle s;
    s = MADTextStyleMake(bold.boolValue,
                         strikethrough.boolValue,
                         italic.boolValue,
                         underline.boolValue);
    return [NSValue valueWithBytes:&s objCType:@encode(MADTextStyle)];
}

- (NSValue *)migrateValueFromSizeWidth:(NSNumber *)width height:(NSNumber *)height {
    CGSize s = CGSizeMake(width.floatValue, height.floatValue);
    return [NSValue valueWithBytes:&s objCType:@encode(CGSize)];
}

- (NSValue *)migrateValueFromBorderHeightBottom:(NSNumber *)heightBottom
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

    float l, r, t, b;
    int16_t ls, rs, ts, bs;
    
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)widthLeft, kCFNumberFloatType, &l);
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)widthRight, kCFNumberFloatType, &r);
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)heightTop, kCFNumberFloatType, &t);
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)heightBottom, kCFNumberFloatType, &b);
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)styleLeft, kCFNumberSInt16Type, &ls);
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)styleRight, kCFNumberSInt16Type, &rs);
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)styleTop, kCFNumberSInt16Type, &ts);
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)styleBottom, kCFNumberSInt16Type, &bs);
    
    MADLayoutBorderStyle borderStyle;
    borderStyle = MADLayoutBorderStyleMake(l, r, t, b, ls, rs, ts, bs);
    
    return [NSValue valueWithBytes:&borderStyle objCType:@encode(MADLayoutBorderStyle)];
}

- (MADCurrencyFormatter *)migrateCurrencyFormatterForCurrencyEnabled:(NSNumber *)enabled
                                                              locale:(NSString *)locale
                                                        decimalCount:(NSNumber *)decimalCount {
    MADCurrencyFormatter *currency;
    currency.enabled = [enabled boolValue];
    currency.decimalCount = [decimalCount integerValue];
    currency = [[MADCurrencyFormatter alloc] init];
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
