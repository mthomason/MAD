//
//  MTQueryTest.h
//  MAD
//
//  Created by Michael Thomason on 4/2/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryTest_h
#define Reports_MTQueryTest_h

#import <MAD/MTQuery.h>
#import <MADFoundation/MTDataTable.h>

@class MTDatabaseConnection;

@interface MTQueryTest : MTQuery

    @property (nonatomic, weak) MTDatabase *database;
    - (instancetype)initWithObject:(MTDatabaseConnection *)object;

@end

#endif
