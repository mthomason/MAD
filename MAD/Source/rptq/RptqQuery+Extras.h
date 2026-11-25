//
//  RptqQuery+Extras.h
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_RptqQuery_Extras_h
#define Reports_RptqQuery_Extras_h

#import <MAD/RptqQuery.h>
#import <MAD/RptqStoreContext.h>

@class RptqDocument, MADDatabase, RptqDocumentSection, RptqDatabaseSchemaTable, RptqQueryField;

@interface RptqQuery (Extras)

	- (RptqQueryGroup *)queryGroupForIndex:(NSUInteger)index;
	- (NSArray <RptqQueryGroup *> *)sortedQueryGroups;
	- (NSArray *)sortDescriptorsForDatabase:(MADDatabase *)database;
	- (NSUInteger)sectionCount;
	+ (NSUInteger)sectionCountFectch:(int64_t)queryObjectID
				managedObjectContext:(RptqStoreContext *)managedObjectContext;

	/// The composing node's projected output fields, ordered by their output index.
	/// A field with no output key is a join or filter field, not a projection.  Nil
	/// with `error` when the query records fields but none names an output (an
	/// earlier store or an unset projection) -- never an invented order.
	- (nullable NSArray<RptqQueryField *> *)orderedOutputFieldsWithError:(NSError * _Nullable __autoreleasing *)error;

	/// Derives one output key per field, in field order, preserving any field's
	/// existing `outputKey` and naming the rest by their bare schema-field name when
	/// that name is unique, otherwise qualifying a collision with the field's source
	/// alias (`<alias>.<name>`, e.g. `payments.amount`).  `existingKeys` are output
	/// keys already taken elsewhere (other children already added), which a new key
	/// must not reuse.  Keys are deterministic and collision-free.
	+ (NSArray<NSString *> *)composeOutputKeysForFields:(NSArray<RptqQueryField *> *)fields
										  existingKeys:(NSSet<NSString *> *)existingKeys;

@end

#endif
