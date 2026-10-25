//
//  MADLegacyStoreConversion.h
//  MAD
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  A document written before the portable store holds its definition in a Core Data
//  store; opening it converts that store to the portable form.  Conversion needs Core
//  Data, which the MAD framework must not link -- it is the headless engine's base
//  (MAD_LINUX.md) -- so the converter is supplied from outside and reached through
//  this registry.  The application target registers an implementation at load time;
//  a build without one can read and write portable documents but cannot open a
//  legacy one.
//
//  MADStoreConverter is the implementation: it lives beside the app's other
//  Apple-only document code and registers itself in +load.
//

#ifndef MAD_MADLegacyStoreConversion_h
#define MAD_MADLegacyStoreConversion_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const MADLegacyStoreConversionErrorDomain;

/// The legacy store inside an unarchived document: `<guts>/StoreContent/analyitics`.
/// The misspelling is on disk in every document ever written and is load-bearing.
/// The converter and the document both need this layout, so it is stated once here.
FOUNDATION_EXPORT NSString * const MADLegacyStoreDirectory;	// StoreContent
FOUNDATION_EXPORT NSString * const MADLegacyStoreName;		// analyitics

typedef NS_ENUM(NSInteger, MADLegacyStoreConversionErrorCode) {
	MADLegacyStoreConversionErrorConverterUnavailable = 1,
};

@protocol MADDocumentLegacyStoreConverting <NSObject>

/// Converts the legacy store at `legacyStoreURL` (a Core Data SQLite file with its
/// journal siblings) into the portable store at `storeURL`.  The caller owns both
/// locations -- the document unarchives into its guts directory, and conversion
/// overwrites whatever portable store is there.  Returns YES when `storeURL` has
/// been written and is ready to open.
- (BOOL)convertLegacyStoreAtURL:(NSURL *)legacyStoreURL
				  toStoreAtURL:(NSURL *)storeURL
						  error:(NSError * _Nullable __autoreleasing *)error;

@end

/// The process-wide converter.  The app (and the CLI, which compiles the same
/// sources) sets one in +load; a caller that finds none cannot convert.
@interface MADLegacyStoreConversion : NSObject

+ (void)setConverter:(nullable id<MADDocumentLegacyStoreConverting>)converter;
+ (nullable id<MADDocumentLegacyStoreConverting>)converter;

@end

NS_ASSUME_NONNULL_END

#endif
