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

#import "MADStore.h"

@class MADStoreGraph, RptqObject;

NS_ASSUME_NONNULL_BEGIN

@interface RptqStoreContext : NSObject

+ (instancetype)contextWithStore:(MADStore *)store;

@property (nonatomic, strong, readonly) MADStore *store;
@property (nonatomic, assign, readonly, getter=isLoaded) BOOL loaded;

#pragma mark Loading

/// Loads the whole document definition.  Part loads are the app's normal shape; the
/// whole-graph load is here for the conversion fixtures.
- (BOOL)loadAllWithError:(NSError **)error;
- (BOOL)loadPart:(MADStorePart)part error:(NSError **)error;

#pragma mark Reading (faulting)

- (nullable RptqObject *)objectForEntity:(NSString *)entity identifier:(int64_t)identifier;
- (NSArray<RptqObject *> *)objectsForEntity:(NSString *)entity;

#pragma mark Writing

/// A new, dirty object.  A non-positive identifier is minted past the highest the
/// entity already holds, matching how the store allocates surrogates.
- (RptqObject *)insertObjectForEntity:(NSString *)entity identifier:(int64_t)identifier;

- (BOOL)save:(NSError **)error;
- (BOOL)deleteObject:(RptqObject *)object error:(NSError **)error;

#pragma mark Relationships

/// Sets an edge and its inverse, mirroring what Core Data does automatically.  `value`
/// is an RptqObject, an NSNumber identifier, or a collection of either for a to-many.
- (void)setRelationship:(NSString *)name
				  value:(nullable id)value
			   onObject:(RptqObject *)object;

@end

NS_ASSUME_NONNULL_END

#endif
