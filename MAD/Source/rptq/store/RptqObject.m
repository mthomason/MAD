//
//  RptqObject.m
//  MAD
//
//  Copyright © 2026 Everyday Apps LLC. All rights reserved.
//

#import "RptqObject.h"
#import "RptqStoreContext.h"
#import "MADStoreSchema.h"

@implementation RptqObject

+ (instancetype)objectWithBackingObject:(MADStoreObject *)backingObject
						   storeContext:(RptqStoreContext *)storeContext {
	RptqObject *object = [[self alloc] init];
	object->_backingObject = backingObject;
	object->_storeContext = storeContext;
	return object;
}

- (int64_t)identifier { return self.backingObject.identifier; }
- (NSString *)entity { return self.backingObject.entity; }

#pragma mark - Copying

- (id)copyWithZone:(NSZone *)zone {
	RptqObject *copy = [[self.class alloc] init];
	copy->_backingObject = [self.backingObject copy];
	copy->_storeContext = self.storeContext;
	return copy;
}

#pragma mark - Generic KVC

static MADStoreAttribute *MADStoreAttributeNamed(MADStoreEntity *entity, NSString *name) {
	for (MADStoreAttribute *attribute in entity.allAttributes) {
		if ([attribute.name isEqualToString:name]) return attribute;
	}
	return nil;
}

- (id)valueForUndefinedKey:(NSString *)key {
	MADStoreEntity *entity = [[MADStoreSchema sharedSchema] entityNamed:self.entity];
	if (!entity) return [super valueForUndefinedKey:key];

	MADStoreAttribute *attribute = MADStoreAttributeNamed(entity, key);
	if (attribute) return [self.backingObject attributeValue:key];

	MADStoreRelationship *relationship = [entity anyRelationshipNamed:key];
	if (relationship) {
		if (relationship.isToMany) {
			NSArray<NSNumber *> *identifiers = [self.backingObject existingCollectionForName:key];
			if (identifiers.count == 0) return @[];
			NSMutableArray<RptqObject *> *members = [NSMutableArray arrayWithCapacity:identifiers.count];
			for (NSNumber *identifier in identifiers) {
				RptqObject *member = [self.storeContext objectForEntity:relationship.destination
														   identifier:identifier.longLongValue];
				if (member) [members addObject:member];
			}
			return members;
		}
		NSNumber *identifier = [self.backingObject referenceForName:key];
		if (!identifier) return nil;
		return [self.storeContext objectForEntity:relationship.destination
									  identifier:identifier.longLongValue];
	}

	return [super valueForUndefinedKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
	MADStoreEntity *entity = [[MADStoreSchema sharedSchema] entityNamed:self.entity];
	if (!entity) {
		[super setValue:value forUndefinedKey:key];
		return;
	}

	MADStoreAttribute *attribute = MADStoreAttributeNamed(entity, key);
	if (attribute) {
		[self.backingObject setAttributeValue:value forName:key];
		return;
	}

	MADStoreRelationship *relationship = [entity anyRelationshipNamed:key];
	if (relationship) {
		[self.storeContext setRelationship:key value:value onObject:self];
		return;
	}

	[super setValue:value forUndefinedKey:key];
}

@end
