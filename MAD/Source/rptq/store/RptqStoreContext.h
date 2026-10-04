//
//  RptqStoreContext.h
//  MAD
//
//  Copyright © 2026 Everyday Apps LLC. All rights reserved.
//
//  The store-backed replacement for the NSManagedObjectContext role.  It owns an open
//  MADStore and a loaded MADStoreGraph (with inverses completed), and is the single
//  place objects are created, faulted, saved and deleted.  Nothing here imports Core
//  Data; see MAD_STORE_PHASE_C.md.
//

#ifndef MAD_RptqStoreContext_h
#define MAD_RptqStoreContext_h

#import <Foundation/Foundation.h>

#import <MAD/MADStore.h>

@class MADStoreGraph, RptqObject;

NS_ASSUME_NONNULL_BEGIN

/// The change-tracking notifications the store context posts.  The names and the
/// userInfo keys (`RptqStoreContextInsertedObjectsKey` and friends) mirror the Core Data
/// notifications the app's view controllers were written against, but the symbols
/// are ours: the framework must not link Core Data (MAD_LINUX.md).  The change
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
- (BOOL)deleteObject:(RptqObject *)object error:(NSError * __autoreleasing *)error;

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
