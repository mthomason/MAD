//
//  RptqDocumentObjectAggregate+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObjectAggregate.h"
#import "RptqDocument.h"
#import "RptqDocumentObjectFactory.h"
#import "RptqDocumentObject+Extras.h"

typedef NS_ENUM(NSUInteger, MTAggregateGroupType) {
	MTAggregateGroupTypeField = 1,
	MTAggregateGroupTypeFormula = 2
};

@interface RptqDocumentObjectAggregate (Extras) <RptqDocumentObjectFactory>

@end
