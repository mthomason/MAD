//
//  NSPredicate+Creators.h
//  MAD
//
//  Created by Michael on 6/3/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_NSPredicate_Creators_h
#define MAD_NSPredicate_Creators_h

#import <Foundation/NSPredicate.h>

@class NSManagedObjectID, NSExpression;

@interface NSPredicate (Creators)

+ (instancetype)newPredicateObjectWithIdentifier:(int64_t)identifier;
+ (instancetype)newPredicateObjectWithIdentifier:(int64_t)identifier
                                       atKeyPath:(NSString *)keyPath;
+ (instancetype)newPredicateObjectWithNumber:(NSNumber *)identifier
                               andExpression:(NSExpression *)expression;
+ (instancetype)newPredicateObjectWithObjectID:(NSManagedObjectID *)objectID;
+ (instancetype)newPredicateObjectWithObjectID:(NSManagedObjectID *)objectID
                                     atKeyPath:(NSString *)keyPath;

+ (instancetype)newPredicateProperyNotNull:(NSString *)keyPath;

@end

#endif
