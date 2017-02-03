//
//  MADModelQuery.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADModelQuery_h
#define MADModelQuery_h

#import <MAD/MADModel.h>

@class MADModelDatabase, MADModelQueryTable, MADModelQueryLink, MADModelTable,
       NSOrderedSet<__covariant ObjectType>,
       NSMutableDictionary<KeyType, ObjectType>;

@interface MADModelQuery : MADModel
    <MADModelIDProtocol, MADModelDataProtocol>
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier
                            database:(MADModelDatabase *)database;
    @property (nonatomic, readonly, strong) NSOrderedSet <NSManagedObjectID *> *queryTableIDs;
    @property (nonatomic, readonly, strong) NSOrderedSet <NSManagedObjectID *> *queryLinkIDs;
    @property (nonatomic, readonly, strong) NSMutableDictionary <NSManagedObjectID *, MADModelQueryTable *> *tables;
    @property (nonatomic, readonly, strong) NSMutableDictionary <NSManagedObjectID *, MADModelTable *> *tableSchemas;
    @property (nonatomic, readonly, strong) NSMutableDictionary <NSManagedObjectID *, MADModelQueryLink *> *links;
    - (NSSet <NSManagedObjectID *> *)tablesInLinks;
    - (NSSet <NSManagedObjectID *> *)orphanedQueryTables;
    - (void)deleteQueryLinkID:(NSManagedObjectID *)queryLink;
    - (void)deleteQueryTableID:(NSManagedObjectID *)queryTable;
    - (void)insertQueryTableID:(NSManagedObjectID *)queryTableID;
    - (void)insertQueryLinkID:(NSManagedObjectID *)queryLinkID;

@end

#endif /* MADModelQuery_h */
