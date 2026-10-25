//
//  MADQuerySampleDataField.h
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTQuerySampleDataField_h
#define Reports_MTQuerySampleDataField_h

#import <MADAPI/MADQuery.h>
#import <MADAPI/MADDatabaseResultsProtocol.h>

@interface MADQuerySampleDataField : MADQuery <MADDatabaseResultsProtocol, MADQueryFieldKeysProtocol, MADQueryDataTableProtocol, MADQueryDatabaseProtocol>

- (NSString *)getSql:(NSError * __autoreleasing *)error;

@end

#endif
