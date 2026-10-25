//
//  MADPredicateOperator.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/1/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADPredicateOperator_h
#define MADPredicateOperator_h

typedef NS_ENUM(short, MADPredicateOperator) {
	MADPredicateOperatorEqual = 0,
	MADPredicateOperatorNotEqual,
	MADPredicateOperatorGreaterThan,
	MADPredicateOperatorGreaterThanOrEqualTo,
	MADPredicateOperatorLessThan,
	MADPredicateOperatorLessThanOrEqualTo
};

#endif /* MADPredicateOperator_h */
