//
//  NSPredicate+Creators.m
//  MAD
//
//  Created by Michael on 6/3/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "NSPredicate+Creators.h"

#import <Foundation/NSExpression.h>
#import <Foundation/NSComparisonPredicate.h>

#import <MAD/MADModelIDProtocol.h>

@implementation NSPredicate (Creators)

+ (instancetype)newPredicateObjectWithIdentifier:(int64_t)identifier {
    NSString *key = NSStringFromSelector(@selector(identifier));
    return [self newPredicateObjectWithIdentifier:identifier atKeyPath:key];
}

+ (instancetype)newPredicateObjectWithIdentifier:(int64_t)identifier
                                       atKeyPath:(NSString *)keyPath {
    NSNumber *idn = @(identifier);
    return [self newPredicateObjectWithIdentifierWrapper:idn atKeyPath:keyPath];
}

+ (instancetype)newPredicateObjectWithIdentifierWrapper:(NSNumber *)identifier
                                              atKeyPath:(NSString *)keyPath {
    NSExpression *left, *right;
    left = [NSExpression expressionForKeyPath:keyPath];
    right = [NSExpression expressionForConstantValue:identifier];
    return [NSComparisonPredicate predicateWithLeftExpression: left
                                              rightExpression: right
                                                     modifier: NSDirectPredicateModifier
                                                         type: NSEqualToPredicateOperatorType
                                                      options: 0];
}

+ (instancetype)newPredicateObjectWithNumber:(NSNumber *)identifier
                               andExpression:(NSExpression *)expressionKeyPath {
    
    NSExpression *expressionConstValue = [NSExpression expressionForConstantValue:identifier];
    return [NSComparisonPredicate predicateWithLeftExpression: expressionKeyPath
                                              rightExpression: expressionConstValue
                                                     modifier: NSDirectPredicateModifier
                                                         type: NSEqualToPredicateOperatorType
                                                      options: 0];
}


+ (instancetype)newPredicateObjectWithObjectID:(NSManagedObjectID *)objectID {
    NSExpression *left, *right;
    left = [NSExpression expressionForEvaluatedObject];
    right = [NSExpression expressionForConstantValue: objectID];
    return [NSComparisonPredicate predicateWithLeftExpression: left
                                              rightExpression: right
                                                     modifier: NSDirectPredicateModifier
                                                         type: NSEqualToPredicateOperatorType
                                                      options: 0];
}

+ (instancetype)newPredicateObjectWithObjectID:(NSManagedObjectID *)objectID
                                     atKeyPath:(NSString *)keyPath {
    NSExpression *left, *right;
    left = [NSExpression expressionForConstantValue: keyPath];
    right = [NSExpression expressionForConstantValue: objectID];
    return [NSComparisonPredicate predicateWithLeftExpression: left
                                              rightExpression: right
                                                     modifier: NSDirectPredicateModifier
                                                         type: NSEqualToPredicateOperatorType
                                                      options: 0];
}

+ (instancetype)newPredicateProperyNotNull:(NSString *)keyPath {
    NSExpression *expressionKeyPath = [NSExpression expressionForKeyPath:keyPath];
    NSExpression *expressionIsNull = [NSExpression expressionForConstantValue:nil];
    return [NSComparisonPredicate predicateWithLeftExpression: expressionKeyPath
                                              rightExpression: expressionIsNull
                                                     modifier: NSDirectPredicateModifier
                                                         type: NSNotEqualToPredicateOperatorType
                                                      options: 0];
}

@end
