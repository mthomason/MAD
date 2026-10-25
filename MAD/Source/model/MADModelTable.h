//
//  MADModelTable.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  One schema table, keyed by the RptqDatabaseSchemaTable row's identifier: its
//  name and, lazily, its fields (sorted by name).  The schema-side counterpart of
//  MADModelQueryTable; read by the query tab's schema browser.
//

#ifndef MADModelTable_h
#define MADModelTable_h

#import <MAD/MADModel.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/MADModelDataProtocol.h>

@class NSOrderedSet<__covariant ObjectType>, NSDictionary, MADModelDatabase,
	   MADModelField;

@interface MADModelTable : MADModel
	<MADModelIDProtocol, MADModelDataProtocol>

	- (instancetype)initWithIdentifier:(int64_t)identifier
				  managedObjectContext:(RptqStoreContext *)context
								  name:(NSString *)name
							 queryable:(BOOL)queryable NS_DESIGNATED_INITIALIZER;

	@property (nonatomic, weak) MADModelDatabase *inDatabase;
	@property (nonatomic, readonly, strong)     NSString *name;
	@property (nonatomic, readonly, strong)     NSDictionary <NSNumber *, MADModelField *> *fields;
	@property (nonatomic, readonly, strong)     NSOrderedSet <NSNumber *> *fieldIDs;

@end

#endif /* MADModelTable_h */
