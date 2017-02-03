//
//  MADModelQueryLink.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADModelQueryLink_h
#define MAD_MADModelQueryLink_h

#import "MADModel.h"

@class MADTableFieldReference, NSPredicate, NSFetchRequest;

@interface MADModelQueryLink : MADModel
    <MADModelIDProtocol>
    + (NSFetchRequest *)fetchRequest:(NSPredicate *)predicate;
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier
                         leftFieldID:(NSManagedObjectID *)leftFieldID
                        lfIdentifier:(int64_t)lfIdentifier
                         leftTableID:(NSManagedObjectID *)leftTableID
                        ltIdentifier:(int64_t)ltIdentifier
                        rightFieldID:(NSManagedObjectID *)rightFieldID
                        rfIdentifier:(int64_t)rfIdentifier
                        rightTableID:(NSManagedObjectID *)rightTableID
                        rtIdentifier:(int64_t)rtIdentifier;
    @property (nonatomic, readonly, strong)      MADTableFieldReference *leftFieldReference;
    @property (nonatomic, readonly, strong)      MADTableFieldReference *rightFieldReference;
    - (NSSet <MADTableFieldReference *> *)tableFieldReferences;
    - (NSSet <NSManagedObjectID *> *)tables;
@end

#endif /* MADModelQueryLink_h */
