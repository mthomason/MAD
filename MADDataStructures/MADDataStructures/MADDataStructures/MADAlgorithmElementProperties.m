//
//  MADAlgorithmElementColor.m
//  MADDataStructures
//
//  Created by Michael Thomason on 3/12/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADAlgorithmElementProperties.h"

@implementation MADAlgorithmElementProperties

- (instancetype)init {
	id elementProperties = [self initWithColor: MTColorWhite];
	return elementProperties;
}

- (instancetype)initWithColor:(MADAlgorithmColor)algorithmColor {
	if (self = [super init]) {
		_algorithmColor = algorithmColor;
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
	id copy = [[self.class allocWithZone:zone] initWithColor: _algorithmColor];
	return copy;
}

@end
