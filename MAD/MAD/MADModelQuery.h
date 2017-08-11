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
#import <MAD/MADModelDataProtocol.h>

@class MADModelDatabase, MADModelQueryTable, MADModelQueryLink, MADModelTable,
       NSOrderedSet<__covariant ObjectType>,
       NSMutableDictionary<KeyType, ObjectType>;

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
    - (void)deleteQueryLinkID:(NSNumber *)queryLink;
    - (void)deleteQueryTableID:(NSNumber *)queryTable;
    - (void)insertQueryTableID:(NSNumber *)queryTableID;
    - (void)insertQueryLinkID:(NSNumber *)queryLinkID;

@end

#endif /* MADModelQuery_h */
