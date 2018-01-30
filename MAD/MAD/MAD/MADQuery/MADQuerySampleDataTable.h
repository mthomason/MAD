//
//  MADQuerySampleDataTable.h
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQuerySampleDataTable_h
#define Reports_MTQuerySampleDataTable_h

#import <MADAPI/MADQuery.h>

@interface MADQuerySampleDataTable : MADQuery
    <MADQueryFieldKeysProtocol, MADQueryDataTableProtocol, MADQueryDatabaseProtocol,
        MADQueryDatabaseProtocol, MADQueryCredentialProtocol>

    - (NSString *)getSql:(NSError * __autoreleasing *)error;

@end

#endif
