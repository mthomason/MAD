//
//  MADQuerySelectPart.h
//  MAD
//
//  Created by Michael Thomason on 6/9/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTQuery_MADQuerySelectExpression_h
#define Reports_MTQuery_MADQuerySelectExpression_h

#import <Foundation/NSObject.h>
#import <MAD/RptqStoreContext.h>

@class MADDatabase;

@interface MADQuerySelectExpression : NSObject

    - (instancetype)initWithDatabase:(MADDatabase *)database
                              tables:(NSArray *)tables
               usingOnlyActiveFields:(BOOL)onlyActiveFields
             forManagedObjectContext:(RptqStoreContext *)context;

    @property (nonatomic, readwrite, strong) NSString *sql;

@end

#endif
