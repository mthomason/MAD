//
//  MADQueryTest.h
//  MAD
//
//  Created by Michael Thomason on 4/2/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTQueryTest_h
#define Reports_MTQueryTest_h

#import <MADAPI/MADQuery.h>

@class MADDatabaseConnection;

@interface MADQueryTest : MADQuery <MADQueryDatabaseProtocol>

- (instancetype)initWithObject:(MADDatabaseConnection *)object;

@end

#endif
