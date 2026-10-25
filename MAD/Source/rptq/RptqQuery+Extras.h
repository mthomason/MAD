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

@class RptqDocument, MADDatabase, RptqDocumentSection, RptqDatabaseSchemaTable;

@interface RptqQuery (Extras)

	- (RptqQueryGroup *)queryGroupForIndex:(NSUInteger)index;
	- (NSArray <RptqQueryGroup *> *)sortedQueryGroups;
	- (NSArray *)sortDescriptorsForDatabase:(MADDatabase *)database;
	- (NSUInteger)sectionCount;
	+ (NSUInteger)sectionCountFectch:(int64_t)queryObjectID
				managedObjectContext:(RptqStoreContext *)managedObjectContext;

@end

#endif
