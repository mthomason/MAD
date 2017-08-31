//
//  MADDataTableObjectEnumerator.h
//  MAD
//
//  Created by Michael Thomason on 4/21/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDataTableObjectEnumerator_h
#define Reports_MADDataTableObjectEnumerator_h

#import <Foundation/NSEnumerator.h>

@class MADDatabaseConnection, MADQuery;

@interface MADDataTableObjectEnumerator : NSEnumerator

    @property (nonatomic, assign) BOOL addRowId;
    @property (nonatomic, assign) BOOL singleColumnNoWrapper;    //No wrapper on this.

    - (instancetype)initWithDatabaseConnection: (MADDatabaseConnection *)databaseConnection
                                       columns: (NSDictionary *)columns
                                    columnKeys: (NSArray *)columnKeys
                                         query: (MADQuery *)query;

@end

#endif
