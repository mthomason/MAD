//
//  MADQueryBuilderAddPredicateDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/1/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADQueryBuilderAddPredicateDelegate_h
#define MADQueryBuilderAddPredicateDelegate_h

@class RptqQueryPredicate;

@protocol MADQueryAddPredicateDelegate
    - (void)tableViewControllerSchemaAddPredicateDidAddPredicate:(RptqQueryPredicate *)predicate;
@end

#endif /* MADQueryBuilderAddPredicateDelegate_h */
