//
//  MADDataTableLocation.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/7/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDataTableLocation.h"
#import <Foundation/NSValue.h>
#import <Foundation/NSCoder.h>

@interface MADDataTableLocation ()

	- (instancetype)init;
	- (instancetype)initWithCoder:(NSCoder *)decoder;
	- (instancetype)initWithRow:(NSUInteger)row inColumn:(NSUInteger)column;

@end

@implementation MADDataTableLocation

+ (instancetype)newDataTableLocationForRow:(NSUInteger)row inColumn:(NSUInteger)column {
	id result = [[self alloc] initWithRow:row inColumn:column];
	return result;
}

- (instancetype)init {
	if (self = [super init]) {
		self.row = 0;
		self.column = 0;
	}
	return self;
}

- (instancetype)initWithRow:(NSUInteger)row inColumn:(NSUInteger)column {
	if (self = [super init]) {
		self.row = row;
		self.column = column;
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		NSNumber *row = [decoder decodeObjectForKey: NSStringFromSelector(@selector(row))];
		self.row = row.unsignedIntegerValue;

		NSNumber *column = [decoder decodeObjectForKey: NSStringFromSelector(@selector(column))];
		self.column = column.unsignedIntegerValue;
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	NSNumber *row = [[NSNumber alloc] initWithUnsignedInteger: self.row];
	[encoder encodeObject: row forKey: NSStringFromSelector(@selector(row))];
	NSNumber *column = [[NSNumber alloc] initWithUnsignedInteger: self.column];
	[encoder encodeObject: column forKey: NSStringFromSelector(@selector(column))];
}

@end
