//
//  MADQueryBuilderAddPredicateDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/1/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADQueryBuilderAddPredicateDelegate_h
#define MADQueryBuilderAddPredicateDelegate_h

@class RptqQueryPredicate;

@protocol MADQueryAddPredicateProtocol
	- (void)tableViewControllerSchemaAddPredicateDidAddPredicate:(RptqQueryPredicate *)predicate;
@end

#endif /* MADQueryBuilderAddPredicateDelegate_h */
