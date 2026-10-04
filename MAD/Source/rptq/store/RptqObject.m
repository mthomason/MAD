//
//  RptqObject.m
//  MAD
//
//  Copyright © 2026 Everyday Apps LLC. All rights reserved.
//

#import "RptqObject.h"
#import "RptqStoreContext.h"
#import "MADStoreSchema.h"

#import <objc/runtime.h>

@implementation RptqObject

+ (instancetype)objectWithBackingObject:(MADStoreObject *)backingObject
						   storeContext:(RptqStoreContext *)storeContext {
	RptqObject *object = [[self alloc] init];
	object->_backingObject = backingObject;
	object->_storeContext = storeContext;
	return object;
}

- (int64_t)identifier { return self.backingObject.identifier; }
- (void)setIdentifier:(int64_t)identifier { self.backingObject.identifier = identifier; }
- (NSString *)entity { return self.backingObject.entity; }

- (void)awakeFromInsert { }

#pragma mark - Identity

// NSManagedObject gave objectID equality; the store-backed object is the same row
// when its entity and identifier agree.  The entity here is the row's own kind,
// which is stable however the row was reached.
- (BOOL)isEqual:(id)object {
	if (self == object) return YES;
	if (![object isKindOfClass:[RptqObject class]]) return NO;
	RptqObject *other = object;
	return self.identifier == other.identifier && [self.entity isEqualToString:other.entity];
}

- (NSUInteger)hash {
	return (NSUInteger)self.identifier ^ self.entity.hash;
}

#pragma mark - Copying

- (id)copyWithZone:(NSZone *)zone {
	RptqObject *copy = [[self.class alloc] init];
	copy->_backingObject = [self.backingObject copy];
	copy->_storeContext = self.storeContext;
	return copy;
}

#pragma mark - Generic KVC

static MADStoreAttribute *MADStoreAttributeNamed(MADStoreEntity *entity, NSString *name) {
	// The entity's memoized name index; this is the render hot path and must not
	// allocate or scan.
	return [entity anyAttributeNamed:name];
}

- (id)valueForUndefinedKey:(NSString *)key {
	RptqStoreContext * storeContext = self.storeContext;
	MADStoreEntity *entity = [[MADStoreSchema sharedSchema] entityNamed:self.entity];
	if (!entity) return [super valueForUndefinedKey:key];

	MADStoreAttribute *attribute = MADStoreAttributeNamed(entity, key);
	if (attribute) return [self.backingObject attributeValue:key];

	MADStoreRelationship *relationship = [entity anyRelationshipNamed:key];
	if (relationship) {
		if (relationship.isToMany) {
			NSArray<NSNumber *> *identifiers = [self.backingObject existingCollectionForName:key];
			NSMutableArray<RptqObject *> *members = [NSMutableArray arrayWithCapacity:identifiers.count];
			for (NSNumber *identifier in identifiers) {
				RptqObject *member = [storeContext objectForEntity:relationship.destination
														   identifier:identifier.longLongValue];
				if (member) [members addObject:member];
			}
			// The declared property type is an ordered or unordered set, so hand back the
			// matching collection rather than a bare array.
			if (relationship.isOrdered) return [NSOrderedSet orderedSetWithArray:members];
			return [NSSet setWithArray:members];
		}
		NSNumber *identifier = [self.backingObject referenceForName:key];
		if (!identifier) return nil;
		return [storeContext objectForEntity:relationship.destination
									  identifier:identifier.longLongValue];
	}

	return [super valueForUndefinedKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
	RptqStoreContext * storeContext = self.storeContext;
	MADStoreEntity *entity = [[MADStoreSchema sharedSchema] entityNamed:self.entity];
	if (!entity) {
		[super setValue:value forUndefinedKey:key];
		return;
	}

	MADStoreAttribute *attribute = MADStoreAttributeNamed(entity, key);
	if (attribute) {
		// A set that does not change the value is not a change: it must not dirty the
		// row, or an idle designer gesture would rewrite the store on every event.
		id previous = [self.backingObject attributeValue:key];
		if (previous == value || [previous isEqual:value]) return;
		[self.backingObject setAttributeValue:value forName:key];
		[storeContext markObjectChanged:self];
		return;
	}

	MADStoreRelationship *relationship = [entity anyRelationshipNamed:key];
	if (relationship) {
		[storeContext setRelationship:key value:value onObject:self];
		return;
	}

	[super setValue:value forUndefinedKey:key];
}

#pragma mark - Dynamic accessors

// The Rptq headers keep their @dynamic property declarations, so the compiler leaves
// the accessors for runtime.  These install them: one small family of IMPs per scalar
// width, dispatched on the property's type encoding.  The getters talk to
// -valueForUndefinedKey: directly rather than -valueForKey:, which would find the very
// accessor being installed and recurse.

static NSString *RptqSelectorName(SEL selector) {
	return [NSString stringWithUTF8String:sel_getName(selector)];
}

static NSString *RptqKeyFromSetter(SEL selector) {
	NSString *name = RptqSelectorName(selector);
	if (name.length < 5 || ![name hasPrefix:@"set"] || ![name hasSuffix:@":"]) return nil;
	NSString *body = [name substringWithRange:NSMakeRange(3, name.length - 4)];
	NSString *first = [body substringToIndex:1].lowercaseString;
	return [first stringByAppendingString:[body substringFromIndex:1]];
}

static id      RptqGetObject(id self, SEL _cmd) { return [self valueForUndefinedKey:RptqSelectorName(_cmd)]; }
static int64_t RptqGetInt64 (id self, SEL _cmd) { return [[self valueForUndefinedKey:RptqSelectorName(_cmd)] longLongValue]; }
static int32_t RptqGetInt32 (id self, SEL _cmd) { return [[self valueForUndefinedKey:RptqSelectorName(_cmd)] intValue]; }
static int16_t RptqGetInt16 (id self, SEL _cmd) { return (int16_t)[[self valueForUndefinedKey:RptqSelectorName(_cmd)] shortValue]; }
static BOOL    RptqGetBool  (id self, SEL _cmd) { return [[self valueForUndefinedKey:RptqSelectorName(_cmd)] boolValue]; }
static double  RptqGetDouble(id self, SEL _cmd) { return [[self valueForUndefinedKey:RptqSelectorName(_cmd)] doubleValue]; }
static float   RptqGetFloat (id self, SEL _cmd) { return [[self valueForUndefinedKey:RptqSelectorName(_cmd)] floatValue]; }

static void RptqSetObject(id self, SEL _cmd, id value)       { [self setValue:value forUndefinedKey:RptqKeyFromSetter(_cmd)]; }
static void RptqSetInt64 (id self, SEL _cmd, int64_t value)  { [self setValue:@(value) forUndefinedKey:RptqKeyFromSetter(_cmd)]; }
static void RptqSetInt32 (id self, SEL _cmd, int32_t value)  { [self setValue:@(value) forUndefinedKey:RptqKeyFromSetter(_cmd)]; }
static void RptqSetInt16 (id self, SEL _cmd, int16_t value)  { [self setValue:@(value) forUndefinedKey:RptqKeyFromSetter(_cmd)]; }
static void RptqSetBool  (id self, SEL _cmd, BOOL value)     { [self setValue:@(value) forUndefinedKey:RptqKeyFromSetter(_cmd)]; }
static void RptqSetDouble(id self, SEL _cmd, double value)   { [self setValue:@(value) forUndefinedKey:RptqKeyFromSetter(_cmd)]; }
static void RptqSetFloat (id self, SEL _cmd, float value)    { [self setValue:@(value) forUndefinedKey:RptqKeyFromSetter(_cmd)]; }

static char RptqPropertyType(objc_property_t property) {
	const char *attributes = property_getAttributes(property);
	if (!attributes || attributes[0] != 'T') return '@';
	return attributes[1];
}

+ (BOOL)resolveInstanceMethod:(SEL)selector {
	const char *name = sel_getName(selector);
	objc_property_t property = class_getProperty(self, name);
	if (property) {
		switch (RptqPropertyType(property)) {
			case 'q': class_addMethod(self, selector, (IMP)RptqGetInt64,  "q@:"); return YES;
			case 'i': class_addMethod(self, selector, (IMP)RptqGetInt32,  "i@:"); return YES;
			case 's': class_addMethod(self, selector, (IMP)RptqGetInt16,  "s@:"); return YES;
			case 'c':
			case 'B': class_addMethod(self, selector, (IMP)RptqGetBool,   "c@:"); return YES;
			case 'd': class_addMethod(self, selector, (IMP)RptqGetDouble, "d@:"); return YES;
			case 'f': class_addMethod(self, selector, (IMP)RptqGetFloat,  "f@:"); return YES;
			default:  class_addMethod(self, selector, (IMP)RptqGetObject, "@@:"); return YES;
		}
	}

	NSString *setterKey = RptqKeyFromSetter(selector);
	if (setterKey) {
		// setterKey is non-nil here and a valid string always yields a UTF8String.
		objc_property_t setterProperty = class_getProperty(self, (const char *)setterKey.UTF8String);
		if (setterProperty) {
			switch (RptqPropertyType(setterProperty)) {
				case 'q': class_addMethod(self, selector, (IMP)RptqSetInt64,  "v@:q"); return YES;
				case 'i': class_addMethod(self, selector, (IMP)RptqSetInt32,  "v@:i"); return YES;
				case 's': class_addMethod(self, selector, (IMP)RptqSetInt16,  "v@:s"); return YES;
				case 'c':
				case 'B': class_addMethod(self, selector, (IMP)RptqSetBool,   "v@:c"); return YES;
				case 'd': class_addMethod(self, selector, (IMP)RptqSetDouble, "v@:d"); return YES;
				case 'f': class_addMethod(self, selector, (IMP)RptqSetFloat,  "v@:f"); return YES;
				default:  class_addMethod(self, selector, (IMP)RptqSetObject, "v@:@"); return YES;
			}
		}
	}

	if ([RptqObject installGeneratedAccessor:selector]) return YES;

	return [super resolveInstanceMethod:selector];
}

#pragma mark - Generated relationship accessors

static NSString *RptqLowercaseFirst(NSString *string) {
	if (string.length == 0) return string;
	return [[string substringToIndex:1].lowercaseString stringByAppendingString:[string substringFromIndex:1]];
}

+ (BOOL)installGeneratedAccessor:(SEL)selector {
	NSString *name = RptqSelectorName(selector);
	NSString *relationship = nil;
	BOOL appends = NO, removes = NO, takesSet = NO;

	if ([name hasPrefix:@"add"] && [name hasSuffix:@"Object:"]) {
		relationship = [name substringWithRange:NSMakeRange(3, name.length - 3 - 7)];
		appends = YES;
	} else if ([name hasPrefix:@"remove"] && [name hasSuffix:@"Object:"]) {
		relationship = [name substringWithRange:NSMakeRange(6, name.length - 6 - 7)];
		removes = YES;
	} else if ([name hasPrefix:@"add"] && [name hasSuffix:@":"]) {
		relationship = [name substringWithRange:NSMakeRange(3, name.length - 3 - 1)];
		appends = YES; takesSet = YES;
	} else if ([name hasPrefix:@"remove"] && [name hasSuffix:@":"]) {
		relationship = [name substringWithRange:NSMakeRange(6, name.length - 6 - 1)];
		removes = YES; takesSet = YES;
	}
	if (!relationship) return NO;

	NSString *key = RptqLowercaseFirst(relationship);

	IMP implementation = NULL;
	const char *encoding = "v@:@";
	if (appends && !takesSet) {
		implementation = imp_implementationWithBlock(^(RptqObject *target, id object) {
			[target.storeContext addObject:object toRelationshipNamed:key onObject:target];
		});
	} else if (removes && !takesSet) {
		implementation = imp_implementationWithBlock(^(RptqObject *target, id object) {
			[target.storeContext removeObject:object fromRelationshipNamed:key onObject:target];
		});
	} else if (appends && takesSet) {
		implementation = imp_implementationWithBlock(^(RptqObject *target, id collection) {
			// Read the weak store once: it cannot vanish between members, and this is
			// the accessor path, so the extra weak loads would be their own cost.
			RptqStoreContext *storeContext = target.storeContext;
			for (id member in collection) [storeContext addObject:member toRelationshipNamed:key onObject:target];
		});
	} else if (removes && takesSet) {
		implementation = imp_implementationWithBlock(^(RptqObject *target, id collection) {
			RptqStoreContext *storeContext = target.storeContext;
			for (id member in collection) [storeContext removeObject:member fromRelationshipNamed:key onObject:target];
		});
	}

	if (implementation) {
		class_addMethod(self, selector, implementation, encoding);
		return YES;
	}
	return NO;
}

@end
