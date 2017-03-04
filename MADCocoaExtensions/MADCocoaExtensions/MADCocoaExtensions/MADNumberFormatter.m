//
//  NSNumberFormatter+Constructors.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 6/1/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADNumberFormatter.h"

static NSString * const TextDecimalSeparator = @".";
static NSString * const TextGroupingSeparator = @",";

@implementation MADNumberFormatter

+ (instancetype)newNumberFormatterTwoDecimalPlaces {
    id numberFormatter = [[self alloc] init];

    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
    [numberFormatter setMaximumFractionDigits: 2];
    [numberFormatter setDecimalSeparator: TextDecimalSeparator];
    [numberFormatter setGroupingSeparator: TextGroupingSeparator];
    
    return numberFormatter;
}

@end
