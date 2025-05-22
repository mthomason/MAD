//
//  MADCurrencyFormatter.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADCurrencyFormatter_h
#define MAD_MADCurrencyFormatter_h

#import <Foundation/NSObject.h>

@interface MADCurrencyFormatter : NSObject <NSSecureCoding>

	@property (nonatomic, assign) BOOL enabled;
	@property (nonatomic, assign) NSInteger decimalCount;
	@property (nonatomic, strong) NSLocale *locale;

	+ (BOOL)supportsSecureCoding;

@end

#endif
