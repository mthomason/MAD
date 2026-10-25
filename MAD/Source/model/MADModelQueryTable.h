//
//  MADModelQueryTable.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  One table pulled into a query, keyed by the RptqQueryTable row's identifier:
//  the schema table it stands for, its drop index, and its selected fields
//  (MADModelQueryField).  -alias is the SQL-facing name: "Customer", "Customer0", ...
//

#ifndef MADModelQueryTable_h
#define MADModelQueryTable_h

#import <MAD/MADModel.h>

@class MADModelDatabase, MADModelQuery, MADModelQueryField, NSPredicate,
		NSMutableDictionary, NSMutableOrderedSet<ObjectType>;

@interface MADModelQueryTable : MADModel <MADModelIDProtocol>

@property (nonatomic, weak) MADModelQuery *inQuery;
@property (nonatomic, readonly) int64_t schemaTable;
@property (nonatomic, readonly) NSNumber *schemaTableID;
@property (nonatomic, readonly, strong) NSMutableDictionary <NSNumber *, MADModelQueryField *> *queryFields;
@property (nonatomic, readonly, strong) NSMutableOrderedSet <NSNumber *> *queryFieldIDs;

- (instancetype)initWithIdentifier:(int64_t)identifier
						 dropIndex:(int64_t)dropIndex
					   schemaTable:(int64_t)schemaTableIdentifier
						inDatabase:(MADModelDatabase *)inDatabase;

- (void)addField:(int64_t)fieldIdentifier
	 schemaField:(int64_t)schemaField;

- (NSString *)alias;

@end

#endif /* MADModelQueryTable_h */
