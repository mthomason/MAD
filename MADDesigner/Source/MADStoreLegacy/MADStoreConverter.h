//
//  MADStoreConverter.h
//  MAD Designer
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The bridge from a legacy Core Data `.mad` to the portable store.  It lives in the
//  application target, not the MAD framework: the framework is the headless engine's
//  base and must not link Core Data (MAD_LINUX.md), so it reaches the converter
//  through MADLegacyStoreConversion's registry instead.  MADStore, MADStoreSchema,
//  MADStoreObject and MADStoreGraph neither know nor care where a graph came from.
//
//  The walk is driven by MADStoreSchema rather than by hand-written code per entity,
//  so the two cannot drift: for every row of the legacy document it writes the
//  attributes the schema declares and the edges the schema declares.  The four
//  transformable attributes are the exception -- a colour becomes four Real columns,
//  an image a PNG blob, a locale its identifier string -- together with the one
//  rename the schema carries, `dbkey` to `key`.
//
//  Ten entities have no identifier in the model: the nine value-type satellites
//  (RptqAlignment, RptqBorder, RptqPoint, ...) and RptqDocumentSectionRows.  They are
//  given one here, numbered past the highest identifier the entity already uses,
//  because MADStoreGraph keys by (entity, identifier) and two rows left at zero would
//  collide.  MADStore then assigns the surrogates the store itself will keep.
//

#ifndef MAD_MADStoreConverter_h
#define MAD_MADStoreConverter_h

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import <MAD/MADStoreGraph.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const MADStoreConverterErrorDomain;

typedef NS_ENUM(NSInteger, MADStoreConverterErrorCode) {
	MADStoreConverterErrorUnarchive = 1,
	MADStoreConverterErrorStoreFileMissing,
	MADStoreConverterErrorUnknownEntity,
	MADStoreConverterErrorModelMissing,
};

@interface MADStoreConverter : NSObject

/// The legacy half of the bridge on its own: unarchive `documentURL` into
/// `directory` and open the Core Data store inside it.  The caller owns `directory`
/// and is expected to remove it once the context is no longer wanted -- the legacy
/// store files live in it.  This is the one place a legacy document is opened, so
/// it is also the only place to look at the rows Core Data holds before they are
/// serialised.  `model` is the momd's current version; a store written against an
/// older version is opened with that version instead, never migrated.
+ (nullable NSManagedObjectContext *)legacyContextForDocumentAtURL:(NSURL *)documentURL
													   extractedTo:(NSURL *)directory
															 model:(NSManagedObjectModel *)model
															 error:(NSError * __autoreleasing *)error;

/// Serialises every row of a legacy Core Data document into a portable store graph.
/// The graph is the reader's canonical shape, so the two compare with -isEqualToGraph:
/// once both have been through -graphByCompletingInverses.
+ (nullable MADStoreGraph *)graphForManagedObjectContext:(NSManagedObjectContext *)context
												   error:(NSError * __autoreleasing *)error;

/// The conversion at the store level, for a caller that already extracted the
/// document and owns both locations: open the legacy store at `legacyStoreURL`,
/// serialise its graph, and write the portable store at `storeURL`.  The document's
/// open path calls this through MADLegacyStoreConversion, inside its own guts
/// directory; the two URL arguments are plain files.
+ (nullable MADStoreGraph *)convertLegacyStoreAtURL:(NSURL *)legacyStoreURL
										toStoreAtURL:(NSURL *)storeURL
											   model:(NSManagedObjectModel *)model
											   error:(NSError * __autoreleasing *)error;

/// The whole bridge: open the legacy `.mad` at `documentURL`, serialise its graph,
/// and write the portable store at `storeURL`.  `model` is the momd's current
/// version; the converter opens the store with the momd version matching its
/// metadata.  Returns the graph that was written, so the caller can compare it
/// with what the store reads back.
+ (nullable MADStoreGraph *)convertDocumentAtURL:(NSURL *)documentURL
									 toStoreAtURL:(NSURL *)storeURL
											model:(NSManagedObjectModel *)model
											error:(NSError * __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END

#endif
