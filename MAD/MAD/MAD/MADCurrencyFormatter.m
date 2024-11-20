//
//  MADCurrencyFormatter.m
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADCurrencyFormatter.h"
#import <Foundation/NSCoder.h>
#import <Foundation/NSLocale.h>
#import <string.h>

@implementation MADCurrencyFormatter

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {

        self.enabled = [aDecoder decodeBoolForKey:@"e"];;
        self.decimalCount = [aDecoder decodeIntegerForKey:@"d"];
        self.locale = [aDecoder decodeObjectOfClass:[NSLocale class] forKey:@"l"];
    
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeBool:self.enabled forKey:@"e"];
    [aCoder encodeInteger:self.decimalCount forKey:@"d"];
    [aCoder encodeObject:self.locale forKey:@"l"];
}

@end
