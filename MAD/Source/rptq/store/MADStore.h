//
//  MADStore.h
//  MAD
//
//  Copyright © 2026 Everyday Apps LLC. All rights reserved.
//
//  The portable store: the document definition kept in a SQLite schema of our own
//  instead of a Core Data store.  Nothing here imports Core Data.
//
//  Reading comes in three shapes.  -objectForEntity:identifier: is the fetch the
//  code does most -- one row by its identifier.  -objectsForEntity: is every row of
//  one entity, flat.  -graphForPart: is a whole part of the document with its edges
//  wired up, which is the granularity the app loads at: the schema part when a
//  connection needs it, the query part in MAD Query, the layout part in MAD
//  Designer.  -graphForEntityNames: and -allObjectsWithError: are the same wiring
//  for a caller that names its own set.
//
//  Writing is per object or per graph.  -writeGraph:replacingAll:error: is the save
//  path: it assigns surrogates where the model has no identifier, writes every row,
//  orders the four ordered to-many relationships by their parent's edge order, and
//  rebuilds the many-to-many join table.
//

#ifndef MAD_MADStore_h
#define MAD_MADStore_h

#import <Foundation/Foundation.h>
#import <MAD/MADStoreSchema.h>
#import <MAD/MADStoreObject.h>
#import <MAD/MADStoreGraph.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const MADStoreErrorDomain;

typedef NS_ENUM(NSInteger, MADStoreErrorCode) {
	MADStoreErrorNotOpen = 1,
	MADStoreErrorSQLite,
	MADStoreErrorUnknownEntity,
	MADStoreErrorUnknownAttribute,
	MADStoreErrorUnwritableAttribute,
};

@interface MADStore : NSObject

+ (instancetype)storeWithURL:(NSURL *)url;
- (instancetype)initWithURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, copy, readonly) NSURL *url;
@property (nonatomic, assign, readonly, getter=isOpen) BOOL open;
@property (nonatomic, strong, readonly) MADStoreSchema *schema;

/// Opens the file, creating the schema when it is not there yet and applying
/// the migration steps the store is behind on (MADStoreSchema.migrations).
- (BOOL)openWithError:(NSError * __autoreleasing *)error;
- (void)close;

#pragma mark Reading

- (nullable MADStoreObject *)objectForEntity:(NSString *)entity
								  identifier:(int64_t)identifier
									   error:(NSError * __autoreleasing *)error;

- (NSArray<MADStoreObject *> *)objectsForEntity:(NSString *)entity error:(NSError * __autoreleasing *)error;

- (nullable MADStoreGraph *)graphForEntityNames:(NSArray<NSString *> *)entityNames
										  error:(NSError * __autoreleasing *)error;
- (nullable MADStoreGraph *)graphForPart:(MADStorePart)part error:(NSError * __autoreleasing *)error;
- (nullable MADStoreGraph *)allObjectsWithError:(NSError * __autoreleasing *)error;

#pragma mark Writing

- (BOOL)writeGraph:(MADStoreGraph *)graph error:(NSError * __autoreleasing *)error;
- (BOOL)writeGraph:(MADStoreGraph *)graph replacingAll:(BOOL)replacingAll error:(NSError * __autoreleasing *)error;
- (BOOL)writeObject:(MADStoreObject *)object error:(NSError * __autoreleasing *)error;

/// The incremental save path: writes exactly the named rows -- plus the position
/// and join-table rows their to-many edges produce -- and deletes the named rows,
/// all in one transaction.  Rows not named are untouched, and a nil `objects`
/// with an empty `deletedObjects` is a successful no-op.
- (BOOL)writeObjects:(NSArray<MADStoreObject *> *)objects
	 deletingObjects:(NSArray<MADStoreObject *> *)deletedObjects
			   error:(NSError * __autoreleasing *)error;

- (BOOL)deleteObjectForEntity:(NSString *)entity identifier:(int64_t)identifier error:(NSError * __autoreleasing *)error;
- (BOOL)deleteAllObjectsWithError:(NSError * __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END

#endif
