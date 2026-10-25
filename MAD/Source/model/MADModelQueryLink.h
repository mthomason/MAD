//
//  MADModelQueryLink.h
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  One join in a query, keyed by the RptqQueryLinks row's identifier: the
//  table+field pair at each end (MADTableFieldIdentifier).  These are the graph
//  edges of the query visualization.
//

#ifndef MAD_MADModelQueryLink_h
#define MAD_MADModelQueryLink_h

#import <MAD/MADModel.h>

@class MADModelQuery, MADTableFieldIdentifier, NSNumber, NSSet<__covariant ObjectType>, RptqQueryLinks;

@interface MADModelQueryLink : MADModel <MADModelIDProtocol>

@property (nonatomic, weak) MADModelQuery *inQuery;
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


- (instancetype)initWithIdentifier:(int64_t)identifier
					   leftFieldID:(int64_t)leftFieldID
					   leftTableID:(int64_t)leftTableID
					  rightFieldID:(int64_t)rightFieldID
					  rightTableID:(int64_t)rightTableID;
- (instancetype)initWithRptqQueryLink:(RptqQueryLinks *)queryLink;

- (BOOL)isAdjacentToQueryTable:(int64_t)queryTableID;
- (NSSet <NSNumber *> *)tables;

@end

#endif /* MADModelQueryLink_h */
