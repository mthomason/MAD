//
//  MADModelQueryLink.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADModelQueryLink_h
#define MAD_MADModelQueryLink_h

#import <MAD/MADModel.h>

@class MADModelQuery, MADTableFieldReference, MADTableFieldIdentifier, NSPredicate, NSFetchRequest, NSNumber, NSSet<__covariant ObjectType>, RptqQueryLinks;

@interface MADModelQueryLink : MADModel <MADModelIDProtocol>

@property (nonatomic, weak) MADModelQuery *inQuery;
@property (nonatomic, readonly, strong) MADTableFieldReference *leftFieldReference;
@property (nonatomic, readonly, strong) MADTableFieldReference *rightFieldReference;
@property (nonatomic, readonly, strong) MADTableFieldIdentifier *leftFieldIdentifier;
@property (nonatomic, readonly, strong) MADTableFieldIdentifier *rightFieldIdentifier;

@property (nonatomic, readonly) NSNumber * leftTableObjectID;
@property (nonatomic, readonly) NSNumber * rightTableObjectID;
@property (nonatomic, readonly) NSNumber * leftFieldObjectID;
@property (nonatomic, readonly) NSNumber * rightFieldObjectID;

@property (nonatomic, readonly) int64_t leftTableID;
@property (nonatomic, readonly) int64_t rightTableID;
@property (nonatomic, readonly) int64_t leftFieldID;
@property (nonatomic, readonly) int64_t rightFieldID;

+ (NSFetchRequest *)fetchRequest:(NSPredicate *)predicate;

- (instancetype)initWithIdentifier:(int64_t)identifier
					   leftFieldID:(int64_t)leftFieldID
					   leftTableID:(int64_t)leftTableID
					  rightFieldID:(int64_t)rightFieldID
					  rightTableID:(int64_t)rightTableID;
- (instancetype)initWithRptqQueryLink:(RptqQueryLinks *)queryLink;

- (BOOL)isAdjacentToQueryTable:(int64_t)queryTableID;

//- (NSSet <MADTableFieldReference *> *)tableFieldReferences;
- (NSSet <NSNumber *> *)tables;

@end

#endif /* MADModelQueryLink_h */
