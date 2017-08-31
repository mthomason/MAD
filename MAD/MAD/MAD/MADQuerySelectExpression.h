//
//  MADQuerySelectPart.h
//  MAD
//
//  Created by Michael Thomason on 6/9/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQuery_MADQuerySelectExpression_h
#define Reports_MTQuery_MADQuerySelectExpression_h

#import <Foundation/NSObject.h>

@class MADDatabase, NSManagedObjectContext;

@interface MADQuerySelectExpression : NSObject

    - (instancetype)initWithDatabase:(MADDatabase *)database
                              tables:(NSArray *)tables
               usingOnlyActiveFields:(BOOL)onlyActiveFields
             forManagedObjectContext:(NSManagedObjectContext *)context;

    @property (nonatomic, readwrite, strong) NSString *sql;

@end

#endif
