//
//  MTQuerySampleDataField.h
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQuerySampleDataField_h
#define Reports_MTQuerySampleDataField_h

#import "MTQuery.h"
#import <MADAPI/MADDatabaseResultsProtocol.h>

@interface MTQuerySampleDataField : MTQuery
    <MADDatabaseResultsProtocol>

    - (NSString *)getSql:(NSError * __autoreleasing *)error;

@end

#endif
