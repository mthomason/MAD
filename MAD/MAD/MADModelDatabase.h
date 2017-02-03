//
//  MADModelDatabase.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADModelDatabase_h
#define MADModelDatabase_h

#import <MAD/MADModel.h>

@interface MADModelDatabase : MADObjectID
    <MADModelIDProtocol, MADModelDataProtocol>

    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier
                             queryID:(NSManagedObjectID *)queryID
                     queryIdentifier:(int64_t)queryIdentifier
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    @property (nonatomic, readonly, strong)     NSOrderedSet <MADModelQuery *> *queries;
    @property (nonatomic, readonly, strong)     NSOrderedSet <MADModelTable *> *tables;
    @property (nonatomic, readonly, weak)       MADModelQuery *firstQuery;
@end

#endif /* MADModelDatabase_h */
