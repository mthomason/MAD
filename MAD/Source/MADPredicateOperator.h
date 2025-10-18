//
//  MADPredicateOperator.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/1/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
