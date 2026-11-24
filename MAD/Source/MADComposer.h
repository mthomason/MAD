//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADComposer.h
//  MAD
//
//  The two-input composition join: two published source results materialized over
//  one MAD SQLite connection into a root result.  A caller describes the logical
//  inputs (their alias, their published result, the projected fields, and the join
//  key), and the composer resolves the physical table and column names, opens a
//  URI-capable connection, attaches each input read-only, runs the join, and hands
//  back a normal MADDataResult.
//
//  The join is serial and in-memory: the two inputs are attached to one scratch
//  connection, and the root lands in a fresh generation-named row table.  A failed
//  attempt closes the connection and leaves both inputs and any prior published
//  root untouched -- it never writes into an input's row file.
//

#ifndef MAD_MADComposer_h
#define MAD_MADComposer_h

#import <Foundation/Foundation.h>

#import <MAD/MADQueryLinkType.h>

NS_ASSUME_NONNULL_BEGIN

@class MADDataResult;

/// One projected column in the root: the field in the input (`sourceKey`, a full
/// logical key as it appears in the input's `MADDataResult.columnKeys`) and the
/// column key it is written as in the root (`outputKey`).
@interface MADComposerField : NSObject
@property (nonatomic, copy) NSString *sourceKey;
@property (nonatomic, copy) NSString *outputKey;
+ (instancetype)fieldWithSourceKey:(NSString *)sourceKey outputKey:(NSString *)outputKey;
@end

/// One input to the join: a published result, the projected fields (in root order),
/// and the join key.  The join key must be present in `result` even when it is not
/// projected, because the root needs it to join on; the composer rejects a missing
/// key rather than silently dropping a row.
@interface MADComposerInput : NSObject
@property (nonatomic, copy) NSString *alias;
@property (nonatomic, strong) MADDataResult *result;
@property (nonatomic, copy) NSArray<MADComposerField *> *fields;
@property (nonatomic, copy) NSString *joinKey;
@end

/// The serial, in-memory composer.
@interface MADComposer : NSObject

/// Compose a root from two published results.  `left` and `right` name the inputs;
/// the root projects `left.fields` then `right.fields`, joined on
/// `left.joinKey` = `right.joinKey` with `joinType`.  `orderByKeys`, when non-empty,
/// appends an ORDER BY over those full logical keys (a text key orders with the
/// LSASC collation the MAD connection registers).  The root lands in
/// `cacheDirectory` under `rootIdentifier`.
///
/// Returns nil with `error` set when an input is missing, a required field or join
/// key is absent from its input, the attach fails, or the join fails.  A failure
/// leaves the inputs and any prior published root usable.
+ (nullable MADDataResult *)composeLeft:(MADComposerInput *)left
                                  right:(MADComposerInput *)right
                                joinType:(MADLinkType)joinType
                             orderByKeys:(nullable NSArray<NSString *> *)orderByKeys
                          rootIdentifier:(NSString *)rootIdentifier
                          cacheDirectory:(NSURL *)cacheDirectory
                                    error:(NSError * _Nullable __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END

#endif
