//
//  MTGraph+RptqQuery.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/3/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <MADDataStructures/MTGraph.h>

@class RptqQuery;

@interface MTGraph (RptqQuery)

- (instancetype)initWithQuery:(RptqQuery *)query;

@end
