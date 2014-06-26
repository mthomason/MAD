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

+ (id)value:(id)value withType:(SCVarableType)type {
    id result = [[MADValue alloc] initWithValue:value andType:type];
    return result;
}

+ (id)nullValue {
    return [self value:nil withType:SCVarableTypeNull];
}

@end
