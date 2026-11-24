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

@end

#endif
