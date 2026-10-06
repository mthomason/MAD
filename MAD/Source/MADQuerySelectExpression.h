//
//  MADQuerySelectPart.h
//  MAD
//
//  Created by Michael Thomason on 6/9/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
