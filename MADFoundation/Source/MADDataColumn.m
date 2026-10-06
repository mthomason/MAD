//
//  DataColumn.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDataColumn.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#if __APPLE__
#import <CoreFoundation/CFNumber.h>
#endif

// Property lists cannot carry NSNull, so a null default is written as this
// sentinel and must be read back as NSNull. Both sides use this constant.
static NSString * const MADDataColumnNullSentinel = @"~MTNull~";

@interface MADDataColumn ()

	@property (nonatomic, copy, readwrite) NSString *identifier;
	@property (nonatomic, strong) NSMutableArray *column;

@end

@implementation MADDataColumn

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
	MADDataColumn *copy = [[[self class] allocWithZone:zone] init];
	if (copy) {
		copy.identifier = [self.identifier copy];
		copy.defaultValue = [self.defaultValue copy];
		copy.type = self.type;
		copy.nativeType = self.nativeType;
		copy.dataLength = self.dataLength;
		copy.dataPercision = self.dataPercision;
		copy.caption = [self.caption copy];
		copy.fieldName = [self.fieldName copy];
		copy.primaryKey = self.primaryKey;
		copy.notNull = self.notNull;
		copy.autoIncrement = self.autoIncrement;
		copy.column = [self.column mutableCopy];
	}

	return copy;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:  self.fieldName      forKey: [MADDataColumn keyFieldName]];
	[encoder encodeObject:  self.identifier     forKey: [MADDataColumn keyIdentifier]];
	[encoder encodeObject:  self.column         forKey: [MADDataColumn keyColumn]];
	[encoder encodeObject:  self.defaultValue   forKey: [MADDataColumn keyDefaultValue]];
	[encoder encodeObject:  self.caption        forKey: [MADDataColumn keyCaption]];
	[encoder encodeInt64:   self.type           forKey: [MADDataColumn keyColumnType]];
	[encoder encodeInt:     self.nativeType     forKey: [MADDataColumn keyNativeColumnType]];
	[encoder encodeInt64:   self.dataLength     forKey: [MADDataColumn keyDataLength]];
	[encoder encodeInteger: self.dataPercision  forKey: [MADDataColumn keyDataPercision]];
	[encoder encodeBool: _primaryKey       forKey: [MADDataColumn keyIsPrimaryKey]];
	[encoder encodeBool: _notNull          forKey: [MADDataColumn keyIsNotNull]];
	[encoder encodeBool: _autoIncrement    forKey: [MADDataColumn keyIsAutoIncrement]];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		self.fieldName =            [decoder decodeObjectForKey: [MADDataColumn keyFieldName]];
		self.identifier =           [decoder decodeObjectForKey: [MADDataColumn keyIdentifier]];
		self.column =               [decoder decodeObjectForKey: [MADDataColumn keyColumn]];
		self.defaultValue =         [decoder decodeObjectForKey: [MADDataColumn keyDefaultValue]];
		self.caption =              [decoder decodeObjectForKey: [MADDataColumn keyCaption]];
		self.type =                 (int16_t)[decoder decodeIntForKey:  [MADDataColumn keyColumnType]];
		self.nativeType =           (int16_t)[decoder decodeIntForKey: [MADDataColumn keyNativeColumnType]];
		self.dataLength =           [decoder decodeIntegerForKey: [MADDataColumn keyDataLength]];
		self.dataPercision =        [decoder decodeIntForKey: [MADDataColumn keyDataPercision]];
		self.primaryKey =           [decoder decodeBoolForKey: [MADDataColumn keyIsPrimaryKey]];
		self.notNull =              [decoder decodeBoolForKey: [MADDataColumn keyIsNotNull]];
		self.autoIncrement =        [decoder decodeBoolForKey: [MADDataColumn keyIsAutoIncrement]];
	}
	return self;
}

- (instancetype)initWithType:(MADDataType)columnType
						name:(NSString *)name
					  number:(int)columnNumber
					 dataLen:(int)dataLength
				 indexOfType:(int)indexOfType
					  length:(NSInteger)length
				   percision:(int32_t)percision
				  nativeType:(int16_t)nativeType {
	if (self = [super init]) {
		self.column = [[NSMutableArray alloc] init];
		self.type = columnType;
		self.identifier = name.copy;
		self.caption = name.copy;
		self.fieldName = name.copy;
		self.nativeType = nativeType;
		self.dataLength = dataLength;
		self.dataPercision = percision;
	}
	return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
	if (self = [super init]) {
		self.identifier = [identifier copy];
		self.caption = [identifier copy];
		self.fieldName = [identifier copy];
		self.column = [[NSMutableArray alloc] init];
		self.defaultValue = [NSNull null];
		self.type = 0;
		self.nativeType = 0;
		self.dataLength = 0;
		self.dataPercision = 0;
		self.primaryKey = NO;
		self.notNull = NO;
		self.autoIncrement = NO;
	}
	return self;
}

- (instancetype)initWithPlist:(NSDictionary *)plist {
	if (self = [super init]) {
		self.fieldName = [plist[[MADDataColumn keyFieldName]] copy];
		self.identifier = [plist[[MADDataColumn keyIdentifier]] copy];
		NSArray *columnImmutable = plist[[MADDataColumn keyColumn]];
		if (plist[[MADDataColumn keyColumn]] != nil) {
			self.column = [[NSMutableArray alloc] initWithArray:columnImmutable];
		}
		id defaultValue = plist[[MADDataColumn keyDefaultValue]];
		self.defaultValue = [defaultValue isEqual:MADDataColumnNullSentinel] ? [NSNull null] : [defaultValue copy];
		self.caption = [plist[[MADDataColumn keyCaption]] copy];
		self.type = ((NSNumber *)plist[[MADDataColumn keyColumnType]]).shortValue;
		self.nativeType = ((NSNumber *)plist[[MADDataColumn keyNativeColumnType]]).shortValue;
		self.dataLength = ((NSNumber *)plist[[MADDataColumn keyDataLength]]).integerValue;
		self.dataPercision = ((NSNumber *)plist[[MADDataColumn keyDataPercision]]).intValue;
		self.primaryKey = ((NSNumber *)plist[[MADDataColumn keyIsPrimaryKey]]).boolValue;
		self.notNull = ((NSNumber *)plist[[MADDataColumn keyIsNotNull]]).boolValue;
		self.autoIncrement = ((NSNumber *)plist[[MADDataColumn keyIsAutoIncrement]]).boolValue;
	}
	return self;
}

+ (MADDataColumn *)newDataColumnWithIdentifier:(NSString *)identifier {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:identifier];
	column.type = MADDataTypeInteger;
	column.primaryKey = YES;
	column.notNull = YES;
	column.autoIncrement = NO;
	return column;
}

- (NSString *)description {
    	return [NSString stringWithFormat:@"<%@: %p> %@ (%@) %@ %@ %@ %@", NSStringFromClass([self class]), self, self.fieldName, self.identifier, self.caption, self.column, @(self.type), @(self.nativeType)];
}

- (NSString *)debugDescription {
	return [NSString stringWithFormat:@"<%@: %p> %@ (%@) %@ %@ %@ %@", NSStringFromClass([self class]), self, self.fieldName, self.identifier, self.caption, self.column, @(self.type), @(self.nativeType)];
}

- (id)objectAtIndex:(NSUInteger)index {
	NSAssert(index < [self.column count], @"Column doesn't exit!");
	return self.column[index];
}

- (void)addObject:(id)object {
	[self.column addObject:object];
}

- (void)addRows:(NSUInteger)count {
	for (NSUInteger i = 0; i < count; i++) {
		[self.column addObject:self.defaultValue];
	}
}

- (NSDictionary *)copyPlist {
	const NSUInteger plistCapacity = 12;
	NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithCapacity: (plistCapacity + 1)];

	plist[[MADDataColumn keyFieldName]] = [self.fieldName copy];
	plist[[MADDataColumn keyIdentifier]] = [_identifier copy];
	plist[[MADDataColumn keyColumn]] = [_column copy];
	plist[[MADDataColumn keyDefaultValue]] = [_defaultValue isEqual:[NSNull null]] ? MADDataColumnNullSentinel : [_defaultValue copy];
	plist[[MADDataColumn keyCaption]] = [self.caption copy];
	plist[[MADDataColumn keyColumnType]] = [[NSNumber alloc] initWithShort:_type];
	plist[[MADDataColumn keyNativeColumnType]] = [[NSNumber alloc] initWithInteger:_nativeType];
	plist[[MADDataColumn keyIsPrimaryKey]] = [[NSNumber alloc] initWithBool:_primaryKey];
	plist[[MADDataColumn keyIsNotNull]] = [[NSNumber alloc] initWithBool:_notNull];
	plist[[MADDataColumn keyIsAutoIncrement]] = [[NSNumber alloc] initWithBool:_autoIncrement];

#if __APPLE__
	CFNumberRef dataLen = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &_dataLength);
	plist[[MADDataColumn keyDataLength]] = (__bridge id _Nullable)(dataLen);
	CFRelease(dataLen);

	CFNumberRef dataPer = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &_dataPercision);
	plist[[MADDataColumn keyDataPercision]] = (__bridge id _Nullable)(dataPer);
	CFRelease(dataPer);
#else
	// No CoreFoundation on GNUstep; a boxed number holds the same value and
	// serializes to the same plist the CFNumber produces on Apple.
	plist[[MADDataColumn keyDataLength]] = @(_dataLength);
	plist[[MADDataColumn keyDataPercision]] = @(_dataPercision);
#endif

	return plist;
}

- (void)removeAllObjects { [self.column removeAllObjects]; }

+ (NSString *)keyDefaultValue { return NSStringFromSelector(@selector(defaultValue)); }
+ (NSString *)keyCaption { return NSStringFromSelector(@selector(caption)); }
+ (NSString *)keyColumnType { return NSStringFromSelector(@selector(type)); }
+ (NSString *)keyNativeColumnType { return NSStringFromSelector(@selector(nativeType)); }
+ (NSString *)keyDataLength { return NSStringFromSelector(@selector(dataLength)); }
+ (NSString *)keyDataPercision { return NSStringFromSelector(@selector(dataPercision)); }
+ (NSString *)keyIdentifier { return NSStringFromSelector(@selector(identifier)); }
+ (NSString *)keyColumn { return NSStringFromSelector(@selector(column)); }
+ (NSString *)keyIsPrimaryKey { return NSStringFromSelector(@selector(isPrimaryKey)); }
+ (NSString *)keyIsNotNull { return NSStringFromSelector(@selector(isNotNull)); }
+ (NSString *)keyIsAutoIncrement { return NSStringFromSelector(@selector(isAutoIncrement)); }
+ (NSString *)keyFieldName { return NSStringFromSelector(@selector(fieldName)); }

@end
