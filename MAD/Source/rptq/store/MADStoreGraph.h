//
//  MADStoreGraph.h
//  MAD
//
//  Copyright © 2026 Everyday Apps LLC. All rights reserved.
//
//  A set of MADStoreObjects, keyed by entity and identifier.  This is what the
//  reader hands back and the writer consumes; it is the in-memory form of a whole
//  document definition, or of one part of one.
//
//  An edge may be set from either end, but an ordered to-many carries its order on
//  the parent.  -graphByCompletingInverses returns a copy with every edge present
//  from both ends, which is the form the reader produces and the form two graphs
//  are meaningfully compared in.
//

#ifndef MAD_MADStoreGraph_h
#define MAD_MADStoreGraph_h

#import <Foundation/Foundation.h>
#import "MADStoreObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface MADStoreGraph : NSObject

- (void)addObject:(MADStoreObject *)object;
- (nullable MADStoreObject *)objectForEntity:(NSString *)entity identifier:(int64_t)identifier;
- (MADStoreObject *)objectForEntity:(NSString *)entity
						 identifier:(int64_t)identifier
					createIfMissing:(BOOL)createIfMissing;

- (NSArray<MADStoreObject *> *)objectsForEntity:(NSString *)entity;
/// Every object, ordered by entity name and then identifier, so iteration is stable.
- (NSArray<MADStoreObject *> *)allObjects;
- (NSArray<NSString *> *)entityNames;

@property (nonatomic, readonly) NSUInteger count;

/// A deep copy with every edge present from both ends.  Where an ordered to-many
/// exists only as child-to-parent references, the order is materialised by entity
/// name and identifier; an order given on the parent is left alone.
- (MADStoreGraph *)graphByCompletingInverses;

- (BOOL)isEqualToGraph:(MADStoreGraph *)other;

@end

NS_ASSUME_NONNULL_END

#endif
