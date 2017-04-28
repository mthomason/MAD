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

@class MADModelQuery, MADTableFieldReference, MADTableFieldIdentifier, NSPredicate, NSFetchRequest;

@interface MADModelQueryLink : MADModel
    <MADModelIDProtocol>

    + (NSFetchRequest *)fetchRequest:(NSPredicate *)predicate;

    - (instancetype)initWithIdentifier:(int64_t)identifier
                           leftFieldID:(int64_t)leftFieldID
                           leftTableID:(int64_t)leftTableID
                          rightFieldID:(int64_t)rightFieldID
                          rightTableID:(int64_t)rightTableID;

    @property (nonatomic, weak) MADModelQuery *inQuery;
    @property (nonatomic, readonly, strong) MADTableFieldReference *leftFieldReference;
    @property (nonatomic, readonly, strong) MADTableFieldReference *rightFieldReference;
    @property (nonatomic, readonly, strong) MADTableFieldIdentifier *leftFieldIdentifier;
    @property (nonatomic, readonly, strong) MADTableFieldIdentifier *rightFieldIdentifier;

    - (NSSet <MADTableFieldReference *> *)tableFieldReferences;
    - (NSSet <NSNumber *> *)tables;

@end

#endif /* MADModelQueryLink_h */
