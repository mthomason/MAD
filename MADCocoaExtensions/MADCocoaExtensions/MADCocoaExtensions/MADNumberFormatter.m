//
//  NSNumberFormatter+Constructors.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 6/1/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADNumberFormatter.h"

@implementation MADNumberFormatter

+ (instancetype)newNumberFormatterTwoDecimalPlaces {
	id numberFormatter = [[self alloc] init];

	[numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
	[numberFormatter setMaximumFractionDigits: 2];
	[numberFormatter setDecimalSeparator: @"."];
	[numberFormatter setGroupingSeparator: @","];
	
	return numberFormatter;
}

@end
