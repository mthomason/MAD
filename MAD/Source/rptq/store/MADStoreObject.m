//
//  MADStoreObject.m
//  MAD
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADStoreObject.h"

@interface MADStoreObject ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *values;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *references;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<NSNumber *> *> *collections;
@end

@implementation MADStoreObject

+ (instancetype)objectWithEntity:(NSString *)entity identifier:(int64_t)identifier {
	MADStoreObject *object = [MADStoreObject new];
	object.entity = entity;
	object.identifier = identifier;
	return object;
}

- (instancetype)init {
	self = [super init];
	if (!self) return nil;
	_values = [NSMutableDictionary dictionary];
	_references = [NSMutableDictionary dictionary];
	_collections = [NSMutableDictionary dictionary];
	return self;
}

- (id)attributeValue:(NSString *)name { return self.values[name]; }

- (void)setAttributeValue:(id)value forName:(NSString *)name {
	if (value == nil) {
		[self.values removeObjectForKey:name];
	} else {
		self.values[name] = value;
	}
}

- (NSNumber *)referenceForName:(NSString *)name { return self.references[name]; }

- (void)setReference:(NSNumber *)identifier forName:(NSString *)name {
	if (identifier == nil) {
		[self.references removeObjectForKey:name];
	} else {
		self.references[name] = identifier;
	}
}

- (NSMutableArray<NSNumber *> *)collectionForName:(NSString *)name {
	NSMutableArray<NSNumber *> *collection = self.collections[name];
	if (!collection) {
		collection = [NSMutableArray array];
		self.collections[name] = collection;
	}
	return collection;
}

- (NSArray<NSNumber *> *)existingCollectionForName:(NSString *)name {
	return self.collections[name];
}

- (id)copyWithZone:(NSZone *)zone {
	MADStoreObject *copy = [MADStoreObject objectWithEntity:self.entity identifier:self.identifier];
	[copy.values addEntriesFromDictionary:self.values];
	[copy.references addEntriesFromDictionary:self.references];
	for (NSString *name in self.collections) {
		copy.collections[name] = [self.collections[name] mutableCopy];
	}
	return copy;
}

- (BOOL)isEqualToObject:(MADStoreObject *)other {
	if (other == self) return YES;
	if (![other isKindOfClass:[MADStoreObject class]]) return NO;
	if (![self.entity isEqualToString:other.entity]) return NO;
	if (self.identifier != other.identifier) return NO;
	if (![self.values isEqualToDictionary:other.values]) return NO;
	if (![self.references isEqualToDictionary:other.references]) return NO;
	return [self.collections isEqualToDictionary:other.collections];
}

- (BOOL)isEqual:(id)object {
	return [self isEqualToObject:object];
}

- (NSUInteger)hash {
	return (NSUInteger)self.identifier ^ self.entity.hash;
}

- (NSString *)description {
	return [[NSString alloc] initWithFormat:@"<%@ %@ %lld %@ refs:%@ edges:%@>",
			NSStringFromClass(self.class), self.entity, (long long)self.identifier,
			self.values, self.references, self.collections];
}

@end
