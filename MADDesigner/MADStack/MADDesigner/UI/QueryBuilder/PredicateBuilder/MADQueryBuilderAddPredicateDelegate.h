//
//  MADQueryBuilderAddPredicateDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/1/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADQueryBuilderAddPredicateDelegate_h
#define MADQueryBuilderAddPredicateDelegate_h

@class RptqQueryPredicate;

@protocol MADQueryAddPredicateProtocol
	- (void)tableViewControllerSchemaAddPredicateDidAddPredicate:(RptqQueryPredicate *)predicate;
@end

#endif /* MADQueryBuilderAddPredicateDelegate_h */
