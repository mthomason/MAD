//
//  MADModelTable.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADModelTable_h
#define MADModelTable_h

#import <MAD/MADModel.h>

@class NSOrderedSet<__covariant ObjectType>, NSDictionary<KeyType, ObjectType>, MADModelDatabase,
       MADModelField;

@interface MADModelTable : MADModel
    <MADModelIDProtocol, MADModelDataProtocol>

    - (instancetype)initWithIdentifier:(int64_t)identifier
                  managedObjectContext:(NSManagedObjectContext *)context
                                  name:(NSString *)name
                             queryable:(BOOL)queryable NS_DESIGNATED_INITIALIZER;

    @property (nonatomic, weak) MADModelDatabase *inDatabase;
    @property (nonatomic, readonly, strong)     NSString *name;
    @property (nonatomic, readonly, strong)     NSDictionary <NSNumber *, MADModelField *> *fields;
    @property (nonatomic, readonly, strong)     NSOrderedSet <NSNumber *> *fieldIDs;

@end

#endif /* MADModelTable_h */
