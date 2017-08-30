//
//  MTQuerySampleDataTable.h
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQuerySampleDataTable_h
#define Reports_MTQuerySampleDataTable_h

#import <MADAPI/MTQuery.h>

@interface MTQuerySampleDataTable : MTQuery
    <MADQueryFieldKeysProtocol, MADQueryDataTableProtocol, MADQueryDatabaseProtocol,
        MADQueryDatabaseProtocol>

    - (NSString *)getSql:(NSError * __autoreleasing *)error;

@end

#endif
