//
//  RptqObject.h
//  MAD
//
//  Copyright © 2026 Everyday Apps LLC. All rights reserved.
//
//  The plain base class the Rptq entities grow into over Phase C: a typed, faulting
//  view over one MADStoreObject row.  It is what an NSManagedObject was -- identity,
//  attributes, relationships -- minus Core Data.  Nothing here imports Core Data.
//
//  Attribute and relationship access routes through MADStoreSchema, which already
//  knows every property's name and type, so a subclass needs no accessor of its own:
//  it declares the same properties it always did, and the generic KVC fall-through
//  below serves them.  See MAD_STORE_PHASE_C.md §2.
//

#ifndef MAD_RptqObject_h
#define MAD_RptqObject_h

#import <Foundation/Foundation.h>

#import <MAD/MADStoreObject.h>

@class RptqStoreContext;

NS_ASSUME_NONNULL_BEGIN

@interface RptqObject : NSObject <NSCopying>

/// The store row this object is a view over.
@property (nonatomic, strong, readonly) MADStoreObject *backingObject;
/// The context that owns this object; the route for faulting and saving.
@property (nonatomic, weak, readonly) RptqStoreContext *storeContext;

@property (nonatomic, assign) int64_t identifier;
@property (nonatomic, readonly, copy) NSString *entity;

+ (instancetype)objectWithBackingObject:(MADStoreObject *)backingObject
						   storeContext:(RptqStoreContext *)storeContext;

/// Called by the store context after a row is inserted, so a subclass can auto-create
/// its value satellites the way Core Data's awakeFromInsert used to (e.g. a rect
/// creating its origin and size).
- (void)awakeFromInsert;

/// The generic hooks the Rptq headers' @dynamic properties resolve to.  A subclass
/// declares `@property … databaseDriverType;` and these serve the getter and setter.
/// The typed accessors themselves are installed by +resolveInstanceMethod: (see the
/// .m), so a subclass keeps its @dynamic declarations unchanged and dot-syntax access
/// keeps working exactly as it did under Core Data.
- (nullable id)valueForUndefinedKey:(NSString *)key;
- (void)setValue:(nullable id)value forUndefinedKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END

#endif
