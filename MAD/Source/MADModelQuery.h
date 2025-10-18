//
//  MADModelQuery.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADModelQuery_h
#define MADModelQuery_h

#import <MAD/MADModel.h>
#import <MAD/MADModelDataProtocol.h>


@class MADModelDatabase, MADModelQueryTable, MADModelQueryLink, MADModelTable, RptqQueryTable, RptqQueryLinks, NSOrderedSet<__covariant ObjectType>, NSMutableDictionary<KeyType, ObjectType>, NSSet<__covariant ObjectType>;

@interface MADModelQuery : MADModel
	<MADModelIDProtocol, MADModelDataProtocol>

	- (instancetype)initWithIdentifier:(int64_t)identifier
							  database:(MADModelDatabase *)database;
	- (instancetype)initWithIdentifier:(int64_t)identifier
				  managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

	@property (nonatomic, weak) MADModelDatabase *inDatabase;
	@property (nonatomic, readonly, strong) NSOrderedSet <NSNumber *> *queryTableIDs;
	@property (nonatomic, readonly, strong) NSOrderedSet <NSNumber *> *queryLinkIDs;
	@property (nonatomic, readonly, strong) NSMutableDictionary <NSNumber *, MADModelQueryTable *> *tables;
	//@property (nonatomic, readonly, strong) NSMutableDictionary <NSNumber *, MADModelTable *> *tableSchemas;
	@property (nonatomic, readonly, strong) NSMutableDictionary <NSNumber *, MADModelQueryLink *> *links;

	- (NSSet <NSNumber *> *)tablesInLinks;
	- (NSSet <NSNumber *> *)orphanedQueryTables;
	- (void)insertQueryTable:(RptqQueryTable *)queryTable;
	- (void)insertQueryLink:(RptqQueryLinks *)queryLink;
	- (void)deleteQueryLinkID:(NSNumber *)queryLink;
	- (void)deleteQueryTableID:(NSNumber *)queryTable;
	- (void)insertQueryTableID:(NSNumber *)queryTableID;
	- (void)insertQueryTableID:(NSNumber *)queryTableID managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
	- (void)insertQueryLinkID:(NSNumber *)queryLinkID;
	- (NSSet <NSNumber /*MADModelQueryLink*/ *> *)linksForQueryTable:(int64_t)queryTableID;

@end

#endif /* MADModelQuery_h */
