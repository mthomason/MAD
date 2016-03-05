//
//  NSNumberFormatter+Constructors.h
//  CocoaExtensions
//
//  Created by Michael Thomason on 6/1/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADExtensions_NSNumberFormatter_Constructors_h
#define MADExtensions_NSNumberFormatter_Constructors_h

#import <Foundation/Foundation.h>

@interface MADNumberFormatter : NSNumberFormatter

+ (instancetype)twoDecimalPlaces NS_RETURNS_RETAINED;

@end

#endif
