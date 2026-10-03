//
//  MADStoreSchema.h
//  MAD
//
//  Copyright © 2026 Everyday Apps LLC. All rights reserved.
//
//  The portable store's schema.  One SQLite table per entity of the document
//  definition, keyed by `identifier`, with a foreign key for every relationship
//  and an explicit `position` column on the four ordered to-many relationships.
//
//  A `.mad` holds three parts and nothing else -- the database schema imported at
//  creation, the query built in MAD Query, and the layout built in MAD Designer.
//  They load independently; see MADStorePart.
//
//  This is the description a non-Apple platform implements to read a document.  It
//  was transcribed from `MAD 3.xcdatamodel` and is now hand-maintained: it does not
//  consult Core Data, and it must not start.  MADStoreSchemaTests cross-checks it
//  against the compiled model so the two cannot drift apart unnoticed.
//
//  Two entity families do not carry an `identifier` in the model -- the value-type
//  satellites (RptqAlignment, RptqPoint, RptqRect, ...) and RptqDocumentSectionRows.
//  Those rows are keyed by a store-assigned surrogate identifier; because foreign
//  keys are table-qualified, a surrogate never has to be unique beyond its table.
//  Entity descriptors that carry a model identifier say so with -hasModelIdentifier.
//

#ifndef MAD_MADStoreSchema_h
#define MAD_MADStoreSchema_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// SQLite storage class of an attribute.  Chosen for the property's declared type,
/// never for how Core Data happened to store it.
typedef NS_ENUM(NSInteger, MADStoreValueType) {
	MADStoreValueTypeInteger = 0,
	MADStoreValueTypeReal,
	MADStoreValueTypeText,
	MADStoreValueTypeBlob,
};

/// The three independently-loaded parts of a document definition.
typedef NS_ENUM(NSInteger, MADStorePart) {
	MADStorePartSchema = 0,
	MADStorePartQuery,
	MADStorePartLayout,
};

/// The column that orders an ordered to-many relationship.  It lives on the child
/// table, next to the foreign key that points back at the parent.
FOUNDATION_EXPORT NSString * const MADStorePositionColumn;

/// Suffix appended to a relationship's name to name its foreign-key column.
FOUNDATION_EXPORT NSString * const MADStoreIdentifierColumnSuffix;

#pragma mark -

@interface MADStoreAttribute : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) MADStoreValueType type;
@property (nonatomic, assign, getter=isOptional) BOOL optional;
/// YES when the attribute is contributed by a subentity of a shared table, and so
/// must be nullable no matter what the attribute itself says.
@property (nonatomic, assign, getter=isSubentityAttribute) BOOL subentityAttribute;

+ (instancetype)attributeWithName:(NSString *)name
							 type:(MADStoreValueType)type
						 optional:(BOOL)optional;

@end

#pragma mark -

@interface MADStoreRelationship : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *destination;
/// The relationship on the destination entity that pairs with this one.
@property (nonatomic, copy) NSString *inverse;
@property (nonatomic, assign, getter=isToMany) BOOL toMany;
@property (nonatomic, assign, getter=isOrdered) BOOL ordered;
/// YES when this entity's table holds the foreign key for the relationship.  For a
/// to-one that is the ordinary case; for the one-to-one pairs exactly one side is
/// chosen to own it, and the other resolves through -inverse.
@property (nonatomic, assign) BOOL ownsForeignKey;
/// The foreign-key column on this table, when -ownsForeignKey.
@property (nonatomic, copy, readonly, nullable) NSString *column;
/// The join table, when the relationship is many-to-many.
@property (nonatomic, copy, nullable) NSString *joinTable;
/// This side's column in the join table, when many-to-many.
@property (nonatomic, copy, nullable) NSString *joinColumn;

+ (instancetype)toOneNamed:(NSString *)name
			   destination:(NSString *)destination
				   inverse:(NSString *)inverse
			  ownsForeignKey:(BOOL)ownsForeignKey;

+ (instancetype)toManyNamed:(NSString *)name
				destination:(NSString *)destination
					inverse:(NSString *)inverse
					ordered:(BOOL)ordered;

+ (instancetype)toManyNamed:(NSString *)name
				destination:(NSString *)destination
					inverse:(NSString *)inverse
				  joinTable:(NSString *)joinTable
				 joinColumn:(NSString *)joinColumn;

@end

#pragma mark -

@interface MADStoreEntity : NSObject

/// The entity name, e.g. `RptqDocumentElementLabel`.
@property (nonatomic, copy) NSString *name;
/// The value written to the table's `kind` column.  Nil for an entity that owns its
/// table; set for a subentity sharing a parent's table.
@property (nonatomic, copy, nullable) NSString *kind;
/// The parent entity name, for a subentity sharing a table.  Nil otherwise.
@property (nonatomic, copy, nullable) NSString *parentName;
/// The SQLite table.  Resolved by MADStoreSchema from -parentName.
@property (nonatomic, copy) NSString *table;
/// Attributes declared on this entity alone; -allAttributes adds the ancestors'.
@property (nonatomic, copy) NSArray<MADStoreAttribute *> *attributes;
@property (nonatomic, copy) NSArray<MADStoreRelationship *> *relationships;
/// Subentities that share this entity's table.  Empty for everything but
/// RptqDocumentElement.
@property (nonatomic, copy) NSArray<MADStoreEntity *> *subentities;

/// YES when the model gives the entity an `identifier` of its own.  NO for the
/// value-type satellites and RptqDocumentSectionRows, which get a surrogate.
@property (nonatomic, assign, readonly) BOOL hasModelIdentifier;
/// YES when one of this entity's to-one relationships is the child end of an
/// ordered to-many, so the table carries a `position` column.
@property (nonatomic, assign, readonly) BOOL hasPositionColumn;
@property (nonatomic, assign, readonly, getter=isSubentity) BOOL subentity;

- (nullable MADStoreAttribute *)attributeNamed:(NSString *)name;
/// Looks in this entity's attributes and its ancestors', for a subentity; the
/// memoized O(1) form the property layer uses.
- (nullable MADStoreAttribute *)anyAttributeNamed:(NSString *)name;
/// Looks in this entity's own relationships only.
- (nullable MADStoreRelationship *)relationshipNamed:(NSString *)name;
/// Looks in this entity's relationships and its ancestors', for a subentity.
- (nullable MADStoreRelationship *)anyRelationshipNamed:(NSString *)name;
- (NSArray<MADStoreAttribute *> *)allAttributes;
- (NSArray<MADStoreRelationship *> *)allRelationships;

@end

#pragma mark -

@interface MADStoreSchema : NSObject

+ (instancetype)sharedSchema;

/// Every descriptor, table owners and subentities alike.
@property (nonatomic, copy, readonly) NSArray<MADStoreEntity *> *entities;
/// One descriptor per table -- the entities that are not subentities.
@property (nonatomic, copy, readonly) NSArray<MADStoreEntity *> *tables;

- (nullable MADStoreEntity *)entityNamed:(NSString *)name;
- (nullable MADStoreEntity *)entityForTable:(NSString *)table;
- (BOOL)entityName:(NSString *)name belongsToPart:(MADStorePart)part;

/// The complete `CREATE TABLE` / `CREATE INDEX` script, generated from the
/// descriptors so the two can never disagree.
- (NSString *)createSchemaSQL;

@end

NS_ASSUME_NONNULL_END

#endif
