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

@class MADModelQueryField, NSFetchRequest, NSPredicate, NSMutableDictionary<KeyType, ObjectType>;

@interface MADModelQueryTable : MADModel
    <MADModelIDProtocol>
    + (NSFetchRequest *)fetchRequest:(NSPredicate *)predicate;
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier
                         schemaTable:(NSManagedObjectID *)schemaTable
               schemaTableIdentifier:(int64_t)schemaTableIdentifier
                            capacity:(NSUInteger)capacity;
    @property (nonatomic, readonly, strong)     NSMutableDictionary <NSManagedObjectID *, MADModelQueryField *> *fields;
    - (void)addField:(NSManagedObjectID *)fieldID
     fieldIdentifier:(int64_t)fieldIdentifier
         schemaField:(NSManagedObjectID *)schemaField
    schemaFieldIdentifier:(int64_t) schemaFieldIdentifier;
@end

#endif /* MADModelQueryTable_h */
