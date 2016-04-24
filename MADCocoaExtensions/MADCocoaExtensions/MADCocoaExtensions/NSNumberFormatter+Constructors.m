//
//  NSNumberFormatter+Constructors.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 6/1/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "NSNumberFormatter+Constructors.h"

static NSString * const TextDecimalSeparator = @".";
static NSString * const TextGroupingSeparator = @",";

@implementation NSNumberFormatter (Constructors)

+ (instancetype)newNumberFormatterTwoDecimalPlaces {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    numberFormatter.maximumFractionDigits = 2;
    numberFormatter.decimalSeparator = TextDecimalSeparator;
    numberFormatter.groupingSeparator = TextGroupingSeparator;
    return numberFormatter;
}

@end
