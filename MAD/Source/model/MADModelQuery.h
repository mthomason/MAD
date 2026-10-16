//
//  MADModelQuery.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//
//  One query, keyed by the RptqQuery row's identifier: which tables it uses
//  (MADModelQueryTable), how they join (MADModelQueryLink), and the insert/delete
//  methods that keep the model in step with store writes and re-post the
//  MADNotification... events the query visualization observes.
//

#ifndef MADModelQuery_h
#define MADModelQuery_h

#import <MAD/MADModel.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/MADModelDataProtocol.h>


@class MADModelDatabase, MADModelQueryTable, MADModelQueryLink, MADModelTable, RptqQueryTable, RptqQueryLinks, NSOrderedSet<__covariant ObjectType>, NSMutableDictionary, NSSet<__covariant ObjectType>;

@interface MADModelQuery : MADModel <MADModelIDProtocol, MADModelDataProtocol>

@property (nonatomic, weak) MADModelDatabase *inDatabase;
@property (nonatomic, readonly, strong) NSOrderedSet <NSNumber *> *queryTableIDs;
@property (nonatomic, readonly, strong) NSOrderedSet <NSNumber *> *queryLinkIDs;
@property (nonatomic, readonly, strong) NSMutableDictionary <NSNumber *, MADModelQueryTable *> *tables;
//@property (nonatomic, readonly, strong) NSMutableDictionary <NSNumber *, MADModelTable *> *tableSchemas;
@property (nonatomic, readonly, strong) NSMutableDictionary <NSNumber *, MADModelQueryLink *> *links;

- (instancetype)initWithIdentifier:(int64_t)identifier
						  database:(MADModelDatabase *)database;
- (instancetype)initWithIdentifier:(int64_t)identifier
			  managedObjectContext:(RptqStoreContext *)managedObjectContext;

- (NSSet <NSNumber *> *)tablesInLinks;
- (NSSet <NSNumber *> *)orphanedQueryTables;
- (void)insertQueryTable:(RptqQueryTable *)queryTable;
- (void)insertQueryLink:(RptqQueryLinks *)queryLink;
- (void)deleteQueryLinkID:(NSNumber *)queryLink;
- (void)deleteQueryTableID:(NSNumber *)queryTable;
- (void)insertQueryTableID:(NSNumber *)queryTableID;
- (void)insertQueryTableID:(NSNumber *)queryTableID managedObjectContext:(RptqStoreContext *)managedObjectContext;
- (void)insertQueryLinkID:(NSNumber *)queryLinkID;
- (NSSet <NSNumber /*MADModelQueryLink*/ *> *)linksForQueryTable:(int64_t)queryTableID;

@end

#endif /* MADModelQuery_h */
