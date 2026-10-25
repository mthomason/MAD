//
//  MADReportplist.m
//  MAD
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADSectionRepresentation.h"
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSData.h>
#import <string.h>

typedef struct __attribute__((__packed__)) {
	int16_t sectionType;
	uint64_t groupLevel;
	uint64_t row;
} MADSectionEncodedData;

/*
static inline uint64_t htonll(uint64_t);
static inline uint64_t ntohll(uint64_t);

static inline uint64_t htonll(uint64_t x) {
	return __DARWIN_OSSwapInt64(x);
}
static inline uint64_t ntohll(uint64_t x) {
	return __DARWIN_OSSwapInt64(x);
}
*/
@implementation MADSectionRepresentation {
	MADSectionEncodedData _data;
}

+ (BOOL)supportsSecureCoding { return YES; }

+ (instancetype)newSectionRepresentation:(MADDocumentSectionType)sectionType
							  groupLevel:(NSUInteger)groupLevel
									 row:(NSUInteger)row {
	return [[self alloc] initSectionRepresentation: sectionType groupLevel: groupLevel row: row];
}

+ (instancetype)newSectionRepresentation:(MADDocumentSectionType)sectionType
									 row:(NSUInteger)row {
	return [[self alloc] initSectionRepresentation: sectionType groupLevel: NSUIntegerMax row: row];
}

- (instancetype)initSectionRepresentation:(MADDocumentSectionType)sectionType
									  row:(NSUInteger)row {
	return [self initSectionRepresentation: sectionType
								groupLevel: NSUIntegerMax
									   row: row];
}

- (instancetype)initSectionRepresentation:(MADDocumentSectionType)sectionType
							   groupLevel:(NSUInteger)groupLevel
									  row:(NSUInteger)row {
	if (self = [super init]) {
		_data.sectionType = sectionType;
		_data.groupLevel = groupLevel;
		_data.row = row;
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	MADSectionEncodedData encoded;
	encoded.sectionType = _data.sectionType;
	encoded.groupLevel = htonll(_data.groupLevel);
	encoded.row = htonll(_data.row);
	
	NSData *data = [NSData dataWithBytes:&encoded length:sizeof(encoded)];
	[encoder encodeObject:data forKey:@"d"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		NSData *encoded = [decoder decodeObjectOfClass:[NSData class] forKey:@"d"];
		if (encoded.length == sizeof(MADSectionEncodedData)) {
			MADSectionEncodedData decoded;
			[encoded getBytes:&decoded length:sizeof(decoded)];
			_data.sectionType = decoded.sectionType;
			_data.groupLevel = ntohll(decoded.groupLevel);
			_data.row = ntohll(decoded.row);
		} else {
			_data.sectionType = 0;
			_data.groupLevel = 0;
			_data.row = 0;
		}
	}
	return self;
}
- (NSUInteger)groupLevel {
	return _data.groupLevel;
}

- (MADDocumentSectionType)sectionType {
	return _data.sectionType;
}

- (NSUInteger)detailRowId {
	return _data.row;
}

- (id)copyWithZone:(NSZone *)zone {
	return [[[self class] allocWithZone:zone] initSectionRepresentation:_data.sectionType
															 groupLevel:_data.groupLevel
																	row:_data.row];
}

- (id)debugQuickLookObject {
	NSMutableString *debugString = [[NSMutableString alloc] init];
	[debugString appendString:@"MADReportplist\n"];
	[debugString appendString:@"-----------------------------\n"];
	[debugString appendFormat:@"Row ID:       %lu\n", (unsigned long)self.detailRowId];
	[debugString appendFormat:@"Section type: %hd\n", self.sectionType];
	[debugString appendFormat:@"Group level:  %lu\n", (unsigned long)self.groupLevel];
	[debugString appendString:@"-----------------------------\n"];
	return debugString;
}

@end
