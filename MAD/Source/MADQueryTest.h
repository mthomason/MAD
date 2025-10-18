//
//  MADQueryTest.h
//  MAD
//
//  Created by Michael Thomason on 4/2/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTQueryTest_h
#define Reports_MTQueryTest_h

#import <MADAPI/MADQuery.h>

@class MADDatabaseConnection;

@interface MADQueryTest : MADQuery <MADQueryDatabaseProtocol>

- (instancetype)initWithObject:(MADDatabaseConnection *)object;

@end

#endif
