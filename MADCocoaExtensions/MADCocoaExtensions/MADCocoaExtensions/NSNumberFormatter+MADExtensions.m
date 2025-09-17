//
//  NSNumberFormatter+Constructors.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 6/1/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "NSNumberFormatter+MADExtensions.h"

@implementation NSNumberFormatter (MADExtensions)

+ (instancetype)ma_twoDecimalPlacesFormatter {
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	formatter.numberStyle = NSNumberFormatterDecimalStyle;
	formatter.maximumFractionDigits = 2;
	formatter.decimalSeparator = @".";
	formatter.groupingSeparator = @",";
	return formatter;
}

@end
