//
//  MADQuerySelectPart.h
//  MAD
//
//  Created by Michael Thomason on 6/9/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RptqQuery;
@class MTDatabase;
@class NSManagedObjectContext;

@interface MADQuerySelectExpression : NSObject

    - (instancetype)initWithDatabase:(MTDatabase *)database
                              tables:(NSArray *)tables
               usingOnlyActiveFields:(BOOL)onlyActiveFields
             forManagedObjectContext:(NSManagedObjectContext *)context;

    @property (nonatomic, readwrite, strong) NSString *sql;

@end
