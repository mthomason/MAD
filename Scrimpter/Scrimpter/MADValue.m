//
//  MADResult.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/26/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADValue.h"

@interface MADValue ()

@property (nonatomic, assign, readwrite) SCVarableType type;
@property (nonatomic, retain, readwrite) id value;
@property (nonatomic, retain) NSNumberFormatter *numberFormatterDecimalLazy;

@end

@implementation MADValue

- (id)initWithValue:(id)value andType:(SCVarableType)type {
    self = [super init];
    if (self) {
        [self setValue:value];
        [self setType:type];
    }
    return self;
}

- (double)doubleValue {
    double r;
    switch (self.type) {
        case SCVarableTypeString:
            r = [[[self numberFormatterDecimal] numberFromString:[self value]] doubleValue];
            break;

        case SCVarableTypeBoolean:
            r = [[self value] boolValue] ? 0 : 1.0;
            break;
        case SCVarableTypeDouble:
            r = [[self value] doubleValue];
            break;
        case SCVarableTypeNull:
            r = NAN;
            break;
        default:
            r = NAN;
            break;
    }
    return r;
}

- (NSString *)stringValue {
    NSString *result;

    switch (self.type) {

        case SCVarableTypeString:
            result = [self value];
            break;
            
        case SCVarableTypeBoolean:
            result = [[self value] boolValue] ? NSLocalizedString(@"YES", @"YES") : NSLocalizedString(@"NO", @"NO");
            break;
            
        case SCVarableTypeDouble:
            result = [[self numberFormatterDecimal] stringFromNumber:[self value]];
            break;

        case SCVarableTypeNull:
            result = @"NULL";
            break;
            
        default:
            result = @"NULL";
            break;
    }
    return result;
}

- (NSNumberFormatter *)numberFormatterDecimal {
    if ([self numberFormatterDecimalLazy] == nil) {
        NSNumberFormatter *nf = [NSNumberFormatter new];
        [nf setNumberStyle:NSNumberFormatterDecimalStyle];
        [self setNumberFormatterDecimalLazy:nf];
    }
    return [self numberFormatterDecimalLazy];
}

+ (id)value:(id)value withType:(SCVarableType)type {
    id result = [[MADValue alloc] initWithValue:value andType:type];
    return result;
}

+ (id)nullValue {
    return [self value:nil withType:SCVarableTypeNull];
}

@end
