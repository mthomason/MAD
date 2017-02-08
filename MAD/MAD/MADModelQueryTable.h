//
//  MADModelQueryTable.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADModelQueryTable_h
#define MADModelQueryTable_h

#import "MADModel.h"

@class MADModelDatabase, MADModelQueryField, NSFetchRequest, NSPredicate,
        NSMutableDictionary<KeyType, ObjectType>, NSOrderedSet<__covariant ObjectType>;

@interface MADModelQueryTable : MADModel
    <MADModelIDProtocol>
    + (NSFetchRequest *)fetchRequest:(NSPredicate *)predicate;
    + (NSFetchRequest *)fetchRequestQueryTables:(NSPredicate *)predicate;
    - (instancetype)initWithIdentifier:(int64_t)identifier
                             dropIndex:(int64_t)dropIndex
                           schemaTable:(int64_t)schemaTableIdentifier
                            inDatabase:(MADModelDatabase *)inDatabase;

    @property (nonatomic, readonly) int64_t schemaTable;
    @property (nonatomic, readonly, strong) NSDictionary <NSNumber *, MADModelQueryField *> *fields;
    @property (nonatomic, readonly, strong) NSOrderedSet <NSNumber *> *fieldIDs;

    - (void)addField:(int64_t)fieldIdentifier
         schemaField:(int64_t)schemaField;

    - (NSString *)alias;

@end

#endif /* MADModelQueryTable_h */
