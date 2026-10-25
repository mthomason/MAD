//
//  MADStoreObject.h
//  MAD
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  One row of the portable store: an entity name, the `identifier` that keys it,
//  its attribute values, and its relationship edges.  Attribute values are keyed by
//  the attribute's name and hold NSNumber (INTEGER/REAL), NSString (TEXT) or NSData
//  (BLOB).  A nil value is stored as absence, never as NSNull, so an unset optional
//  attribute and a NULL column are the same thing.
//
//  A to-one edge is a target identifier in `references`; a to-many edge is an
//  ordered array of identifiers in `collections`.  Ordered to-many relationships
//  carry their order here, on the parent, and the writer turns it into the child's
//  `position` column.
//
//  Most entities also declare an `identifier` attribute in the model.  It is the
//  same value as -identifier and is deliberately not a member of `values`: there is
//  one identity per row, and it is the row key.  A graph that sets `values`"identifier"
//  is rejected by the writer rather than quietly written twice.
//

#ifndef MAD_MADStoreObject_h
#define MAD_MADStoreObject_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADStoreObject : NSObject <NSCopying>

@property (nonatomic, copy) NSString *entity;
@property (nonatomic, assign) int64_t identifier;

@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, id> *values;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSNumber *> *references;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSMutableArray<NSNumber *> *> *collections;

+ (instancetype)objectWithEntity:(NSString *)entity identifier:(int64_t)identifier;

- (nullable id)attributeValue:(NSString *)name;
- (void)setAttributeValue:(nullable id)value forName:(NSString *)name;

- (nullable NSNumber *)referenceForName:(NSString *)name;
- (void)setReference:(nullable NSNumber *)identifier forName:(NSString *)name;

/// The mutable, ordered edge list, created on first use.
- (NSMutableArray<NSNumber *> *)collectionForName:(NSString *)name;
- (nullable NSArray<NSNumber *> *)existingCollectionForName:(NSString *)name;

- (BOOL)isEqualToObject:(MADStoreObject *)other;

@end

NS_ASSUME_NONNULL_END

#endif
