//
//  RptqObject.m
//  MAD
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "RptqObject.h"
#import "RptqStoreContext.h"
#import "MADStoreSchema.h"

#import <objc/runtime.h>

#include <TargetConditionals.h>

#if __APPLE__
#import <CoreGraphics/CGColor.h>
#import <CoreGraphics/CGColorSpace.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIColor.h>
#elif TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif
#endif

#pragma mark - Colours

// Two model properties the schema spreads over four REAL columns each:
// `backgroundColor` is backgroundColorR/G/B/A and `foregroundColor` its four.  Apple
// hands a UIColor back and takes one apart; off Apple, where there is no UIColor, the
// value is an NSArray of the four components in R, G, B, A order.  A colour with all
// four columns absent is unset.
static NSString * const RptqBackgroundColorKey = @"backgroundColor";
static NSString * const RptqForegroundColorKey = @"foregroundColor";

static BOOL RptqIsColorKey(NSString *key) {
	return [key isEqualToString:RptqBackgroundColorKey] || [key isEqualToString:RptqForegroundColorKey];
}

static NSString *RptqColorComponentName(NSString *key, NSString *component) {
	return [key stringByAppendingString:component];
}

static BOOL RptqColorIsSet(MADStoreObject *row, NSString *key) {
	return [row attributeValue:RptqColorComponentName(key, @"R")] != nil ||
		   [row attributeValue:RptqColorComponentName(key, @"G")] != nil ||
		   [row attributeValue:RptqColorComponentName(key, @"B")] != nil ||
		   [row attributeValue:RptqColorComponentName(key, @"A")] != nil;
}

static void RptqReadColorComponents(MADStoreObject *row, NSString *key, double components[4]) {
	components[0] = [[row attributeValue:RptqColorComponentName(key, @"R")] doubleValue];
	components[1] = [[row attributeValue:RptqColorComponentName(key, @"G")] doubleValue];
	components[2] = [[row attributeValue:RptqColorComponentName(key, @"B")] doubleValue];
	NSNumber *alpha = [row attributeValue:RptqColorComponentName(key, @"A")];
	components[3] = alpha != nil ? alpha.doubleValue : 1.0;
}

#if defined(__APPLE__) && TARGET_OS_IPHONE
static BOOL RptqColorComponentsFromValue(id value, double components[4]) {
	if (![value isKindOfClass:[UIColor class]]) return NO;
	UIColor *color = value;
	CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
	if (![color getRed:&red green:&green blue:&blue alpha:&alpha]) {
		// A colour UIKit cannot describe in RGB -- a pattern, or an extended range --
		// is converted into the space the report renders in, as the converter does.
		CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
		CGColorRef converted = CGColorCreateCopyByMatchingToColorSpace(space, kCGRenderingIntentDefault, color.CGColor, NULL);
		CGColorSpaceRelease(space);
		if (!converted) return NO;
		UIColor *srgb = [UIColor colorWithCGColor:converted];
		CGColorRelease(converted);
		if (![srgb getRed:&red green:&green blue:&blue alpha:&alpha]) return NO;
	}
	components[0] = red;
	components[1] = green;
	components[2] = blue;
	components[3] = alpha;
	return YES;
}
#elif defined(__APPLE__) && TARGET_OS_OSX
static BOOL RptqColorComponentsFromValue(id value, double components[4]) {
	if ([value isKindOfClass:[NSColor class]]) {
		NSColor *color = [(NSColor *)value colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
		if (!color) return NO;
		CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
		[color getRed:&red green:&green blue:&blue alpha:&alpha];
		components[0] = red;
		components[1] = green;
		components[2] = blue;
		components[3] = alpha;
		return YES;
	}
	if ([value isKindOfClass:[NSArray class]]) {
		NSArray *array = value;
		if (array.count != 4) return NO;
		for (NSUInteger index = 0; index < 4; index++) {
			if (![array[index] isKindOfClass:[NSNumber class]]) return NO;
			components[index] = [array[index] doubleValue];
		}
		return YES;
	}
	return NO;
}
#else
static BOOL RptqColorComponentsFromValue(id value, double components[4]) {
	if (![value isKindOfClass:[NSArray class]]) return NO;
	NSArray *array = value;
	if (array.count != 4) return NO;
	for (NSUInteger index = 0; index < 4; index++) {
		if (![array[index] isKindOfClass:[NSNumber class]]) return NO;
		components[index] = [array[index] doubleValue];
	}
	return YES;
}
#endif

static id RptqColorValue(const double components[4]) {
#if defined(__APPLE__) && TARGET_OS_IPHONE
	return [UIColor colorWithRed:components[0] green:components[1] blue:components[2] alpha:components[3]];
#elif defined(__APPLE__) && TARGET_OS_OSX
	return [NSColor colorWithRed:components[0] green:components[1] blue:components[2] alpha:components[3]];
#else
	return @[ @(components[0]), @(components[1]), @(components[2]), @(components[3]) ];
#endif
}

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
		if (!identifier) return nil;	// !: Converting a pointer value of type 'NSNumber *' to a primitive boolean value; instead, either compare the pointer to nil or call -boolValue
		return [storeContext objectForEntity:relationship.destination
									  identifier:identifier.longLongValue];
	}

	// The two colours are the one pair of properties the schema keeps as four
	// component columns rather than a column of their own.
	if (RptqIsColorKey(key)) {
		if (!RptqColorIsSet(self.backingObject, key)) return nil;
		double components[4] = { 0.0, 0.0, 0.0, 1.0 };
		RptqReadColorComponents(self.backingObject, key, components);
		return RptqColorValue(components);
	}

	return [super valueForUndefinedKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
	RptqStoreContext * storeContext = self.storeContext;
	MADStoreEntity *entity = [[MADStoreSchema sharedSchema] entityNamed:self.entity];

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

	if (RptqIsColorKey(key) && [self setColorValue:value forKey:key]) return;

	[super setValue:value forUndefinedKey:key];
}

#pragma mark - Colours

- (BOOL)setColorValue:(id)value forKey:(NSString *)key {
	double components[4] = { 0.0, 0.0, 0.0, 0.0 };
	BOOL hasValue = NO;
	if (value != nil) {
		if (!RptqColorComponentsFromValue(value, components)) return NO;
		hasValue = YES;
	}

	double current[4] = { 0.0, 0.0, 0.0, 1.0 };
	BOOL changed = hasValue != RptqColorIsSet(self.backingObject, key);
	if (!changed && hasValue) {
		RptqReadColorComponents(self.backingObject, key, current);
		for (NSUInteger index = 0; index < 4; index++) {
			if (current[index] != components[index]) {
				changed = YES;
				break;
			}
		}
	}
	if (!changed) return YES;

	static NSString * const componentNames[4] = { @"R", @"G", @"B", @"A" };
	for (NSUInteger index = 0; index < 4; index++) {
		[self.backingObject setAttributeValue:(hasValue ? @(components[index]) : nil)
									  forName:RptqColorComponentName(key, componentNames[index])];
	}
	[self.storeContext markObjectChanged:self];
	return YES;
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

// The runtime compares an installed accessor's encoding against the compiled
// call site's, and BOOL is signed char on Apple, unsigned char on GNUstep --
// so the encoding the bool accessors register is per-platform.
#if __APPLE__
#define MAD_RPTQ_BOOL_TYPE "c"
#else
#define MAD_RPTQ_BOOL_TYPE "C"
#endif

// GNUstep's class_getProperty() looks only at the class itself; Apple's walks
// the superclass chain.  Inherited attributes (a label's `alignment`, say) are
// reached by direct message sends throughout the store, so the walk is done
// here for both platforms.
static objc_property_t RptqPropertyNamed(Class cls, const char *name) {
	objc_property_t property = NULL;
	for (Class current = cls; current != Nil; current = class_getSuperclass(current)) {
		property = class_getProperty(current, name);
		if (property) break;
	}
	return property;
}

static char RptqPropertyType(objc_property_t property) {
	const char *attributes = property_getAttributes(property);
	if (!attributes || attributes[0] != 'T') return '@';
	return attributes[1];
}

+ (BOOL)resolveInstanceMethod:(SEL)selector {
	const char *name = sel_getName(selector);
	objc_property_t property = RptqPropertyNamed(self, name);
	if (property) {
		switch (RptqPropertyType(property)) {
			case 'q': class_addMethod(self, selector, (IMP)RptqGetInt64,  "q@:"); return YES;
			case 'i': class_addMethod(self, selector, (IMP)RptqGetInt32,  "i@:"); return YES;
			case 's': class_addMethod(self, selector, (IMP)RptqGetInt16,  "s@:"); return YES;
			case 'c':
			// GNUstep encodes BOOL as 'C' (unsigned char) where Apple uses 'c'.
			case 'C':
			case 'B': class_addMethod(self, selector, (IMP)RptqGetBool,   MAD_RPTQ_BOOL_TYPE "@:"); return YES;
			case 'd': class_addMethod(self, selector, (IMP)RptqGetDouble, "d@:"); return YES;
			case 'f': class_addMethod(self, selector, (IMP)RptqGetFloat,  "f@:"); return YES;
			default:  class_addMethod(self, selector, (IMP)RptqGetObject, "@@:"); return YES;
		}
	}

	NSString *setterKey = RptqKeyFromSetter(selector);
	if (setterKey) {
		// setterKey is non-nil here and a valid string always yields a UTF8String.
		objc_property_t setterProperty = RptqPropertyNamed(self, (const char *)setterKey.UTF8String);
		if (setterProperty) {
			switch (RptqPropertyType(setterProperty)) {
				case 'q': class_addMethod(self, selector, (IMP)RptqSetInt64,  "v@:q"); return YES;
				case 'i': class_addMethod(self, selector, (IMP)RptqSetInt32,  "v@:i"); return YES;
				case 's': class_addMethod(self, selector, (IMP)RptqSetInt16,  "v@:s"); return YES;
				case 'c':
				case 'C':
				case 'B': class_addMethod(self, selector, (IMP)RptqSetBool,   "v@:" MAD_RPTQ_BOOL_TYPE); return YES;
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
