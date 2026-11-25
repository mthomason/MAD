//
//  RptqStoreContext.h
//  MAD
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The store-backed replacement for the NSManagedObjectContext role.  It owns an open
//  MADStore and a loaded MADStoreGraph (with inverses completed), and is the single
//  place objects are created, faulted, saved and deleted.  Nothing here imports Core
//  Data; see docs/project/design/MAD_STORE_PHASE_C.md.
//

#ifndef MAD_RptqStoreContext_h
#define MAD_RptqStoreContext_h

#import <Foundation/Foundation.h>

#import <MAD/MADStore.h>

@class MADStoreGraph, RptqObject, RptqQuery;

NS_ASSUME_NONNULL_BEGIN

/// The change-tracking notifications the store context posts.  The names and the
/// userInfo keys (`RptqStoreContextInsertedObjectsKey` and friends) mirror the Core Data
/// notifications the app's view controllers were written against, but the symbols
/// are ours: the framework must not link Core Data (docs/developers/build/linux.md).  The change
/// notification is coalesced to one post per run-loop turn.
FOUNDATION_EXPORT NSNotificationName const RptqStoreContextObjectsDidChangeNotification;
FOUNDATION_EXPORT NSNotificationName const RptqStoreContextWillSaveNotification;
FOUNDATION_EXPORT NSNotificationName const RptqStoreContextDidSaveNotification;

FOUNDATION_EXPORT NSString * const RptqStoreContextInsertedObjectsKey;
FOUNDATION_EXPORT NSString * const RptqStoreContextUpdatedObjectsKey;
FOUNDATION_EXPORT NSString * const RptqStoreContextDeletedObjectsKey;

@interface RptqStoreContext : NSObject

+ (instancetype)contextWithStore:(MADStore *)store;

@property (nonatomic, strong, readonly) MADStore *store;
@property (nonatomic, assign, readonly, getter=isLoaded) BOOL loaded;

/// Any unsaved insert, attribute set, relationship set, or deletion.
@property (nonatomic, assign, readonly) BOOL hasChanges;

#pragma mark Loading

/// Loads the whole document definition.  Part loads are the app's normal shape; the
/// whole-graph load is here for the conversion fixtures.
- (BOOL)loadAllWithError:(NSError * __autoreleasing *)error;
- (BOOL)loadPart:(MADStorePart)part error:(NSError * __autoreleasing *)error;

#pragma mark Reading (faulting)

- (nullable RptqObject *)objectForEntity:(NSString *)entity identifier:(int64_t)identifier;
- (NSArray<RptqObject *> *)objectsForEntity:(NSString *)entity;

#pragma mark Writing

/// A new, dirty object.  A non-positive identifier is minted past the highest the
/// entity already holds, matching how the store allocates surrogates.
- (RptqObject *)insertObjectForEntity:(NSString *)entity identifier:(int64_t)identifier;

/// The row is new or one of its values changed; the next -save: writes it.  Called
/// by RptqObject's accessors; a caller only reaches for it directly when it has
/// changed a row behind the accessors' back.
- (void)markObjectChanged:(RptqObject *)object;

- (BOOL)save:(NSError * __autoreleasing *)error;

/// Saves a document that carries a composition graph: the store applies the
/// revision-3 schema and version in the same transaction as the rows.
- (BOOL)saveComposed:(NSError * __autoreleasing *)error;

- (BOOL)deleteObject:(RptqObject *)object error:(NSError * __autoreleasing *)error;

#pragma mark Importing a query graph

/// Copies the query graph (queries, databases, their schema, and every query
/// table/field/link/group/predicate/sort) of `sourceContext` into the receiver,
/// remapping every identifier so the imported objects coexist with whatever the
/// destination already holds, even when the two were authored independently with
/// identical names or identifiers. Layout bands, elements, and the source document
/// row are not copied. A relative SQLite source path is resolved to an absolute
/// path against `relativePathBaseURL` (the source document's own file URL) before
/// it is embedded. Returns the imported root query -- the source's explicit root,
/// or its single query -- or nil with `error`. Does not save; the caller saves.
- (nullable RptqQuery *)importQueryGraphFromContext:(RptqStoreContext *)sourceContext
							   relativePathBaseURL:(nullable NSURL *)relativePathBaseURL
											  error:(NSError * __autoreleasing *)error;

#pragma mark Relationships

/// Sets an edge and its inverse, mirroring what Core Data does automatically.  `value`
/// is an RptqObject, an NSNumber identifier, or a collection of either for a to-many.
- (void)setRelationship:(NSString *)name
				  value:(nullable id)value
			   onObject:(RptqObject *)object;

/// The incremental forms the generated `add<X>Object:` / `remove<X>Object:` accessors
/// resolve to; each maintains the inverse like -setRelationship:… does.
- (void)addObject:(id)member toRelationshipNamed:(NSString *)name onObject:(RptqObject *)object;
- (void)removeObject:(id)member fromRelationshipNamed:(NSString *)name onObject:(RptqObject *)object;

@end

NS_ASSUME_NONNULL_END

#endif
