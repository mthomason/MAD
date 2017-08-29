//
//  MADModelDatabase.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADModelDatabase_h
#define MADModelDatabase_h

#import <MADAPI/MADDatabaseType.h>

#import <MAD/MADModel.h>
#import <MAD/MADModelDataProtocol.h>

@class MADModelTable, MADModelQuery, NSOrderedSet<__covariant ObjectType>;

@interface MADModelDatabase : MADModel
    <MADModelIDProtocol, MADModelDataProtocol>

    - (instancetype)initWithIdentifier:(int64_t)identifier
                      queryIdentifier:(int64_t)queryIdentifier
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

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
