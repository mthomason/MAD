//
//  NSPredicate+Creators.m
//  MAD
//
//  Created by Michael on 6/3/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "NSPredicate+Creators.h"
#import <MAD/MADModelIDProtocol.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSComparisonPredicate.h>
#import <Foundation/NSValue.h>

@implementation NSPredicate (Creators)

+ (instancetype)newPredicateObjectWithIdentifier:(int64_t)identifier {
	return [self newPredicateObjectWithIdentifier:identifier
										atKeyPath:NSStringFromSelector(@selector(identifier))];
}

+ (instancetype)newPredicateObjectWithIdentifier:(int64_t)identifier
									   atKeyPath:(NSString *)keyPath {
	return [self newPredicateObjectWithIdentifierWrapper:@(identifier)
											   atKeyPath:keyPath];
}

+ (instancetype)newPredicateObjectWithIdentifierWrapper:(NSNumber *)identifier
											  atKeyPath:(NSString *)keyPath {
	return [NSComparisonPredicate predicateWithLeftExpression: [NSExpression expressionForKeyPath:keyPath]
											  rightExpression: [NSExpression expressionForConstantValue:identifier]
													 modifier: NSDirectPredicateModifier
														 type: NSEqualToPredicateOperatorType
													  options: 0];
}

+ (instancetype)newPredicateObjectWithNumber:(NSNumber *)identifier
							   andExpression:(NSExpression *)expressionKeyPath {
	return [NSComparisonPredicate predicateWithLeftExpression: expressionKeyPath
											  rightExpression: [NSExpression expressionForConstantValue:identifier]
													 modifier: NSDirectPredicateModifier
														 type: NSEqualToPredicateOperatorType
													  options: 0];
}


+ (instancetype)newPredicateProperyNotNull:(NSString *)keyPath {
	return [NSComparisonPredicate predicateWithLeftExpression: [NSExpression expressionForKeyPath:keyPath]
											  rightExpression: [NSExpression expressionForConstantValue:nil]
													 modifier: NSDirectPredicateModifier
														 type: NSNotEqualToPredicateOperatorType
													  options: 0];
}

@end
