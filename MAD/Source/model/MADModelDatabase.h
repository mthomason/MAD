//
//  MADModelDatabase.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The connection, its schema and its queries, keyed by the RptqDatabase row's
//  identifier.  "Database" here means the connection plus its schema plus a query;
//  today a document has exactly one, hence the document's `firstDatabase`.
//

#ifndef MADModelDatabase_h
#define MADModelDatabase_h

#import <MADAPI/MADDatabaseType.h>

#import <MAD/MADModel.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/MADModelDataProtocol.h>

@class MADModelTable, MADModelQuery, NSOrderedSet<__covariant ObjectType>;

@interface MADModelDatabase : MADModel
	<MADModelIDProtocol, MADModelDataProtocol>

	- (instancetype)initWithIdentifier:(int64_t)identifier
					  queryIdentifier:(int64_t)queryIdentifier
				managedObjectContext:(RptqStoreContext *)managedObjectContext;

	@property (nonatomic, readonly, strong)     NSOrderedSet <NSNumber *> *tables;
	@property (nonatomic, readonly, strong)     NSDictionary <NSNumber *, MADModelTable *> *tableDictionary;
	@property (nonatomic, readonly, strong)     NSOrderedSet <MADModelQuery *> *queries;
	@property (nonatomic, readonly, weak)       MADModelQuery *firstQuery;
	@property (nonatomic, readonly, copy)       NSString *driverName;
	@property (nonatomic, readonly, copy)       NSString *schemaName;
	@property (nonatomic, readonly, copy)       NSString *driverID;
	@property (nonatomic, readonly)             MADDatabaseType driverType;

@end

#endif /* MADModelDatabase_h */
