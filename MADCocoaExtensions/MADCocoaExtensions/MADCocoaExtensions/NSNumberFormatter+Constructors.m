//
//  NSNumberFormatter+Constructors.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 6/1/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "NSNumberFormatter+Constructors.h"

@implementation NSNumberFormatter (Constructors)

+ (instancetype)twoDecimalPlaces NS_RETURNS_RETAINED {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    numberFormatter.maximumFractionDigits = 2;
    numberFormatter.decimalSeparator = @".";
    numberFormatter.groupingSeparator = @",";
    return numberFormatter;
}

@end
