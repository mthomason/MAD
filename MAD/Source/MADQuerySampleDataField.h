//
//  MADQuerySampleDataField.h
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTQuerySampleDataField_h
#define Reports_MTQuerySampleDataField_h

#import <MADAPI/MADQuery.h>
#import <MADAPI/MADDatabaseResultsProtocol.h>

@interface MADQuerySampleDataField : MADQuery <MADDatabaseResultsProtocol, MADQueryFieldKeysProtocol, MADQueryDataTableProtocol, MADQueryDatabaseProtocol>

- (NSString *)getSql:(NSError * __autoreleasing *)error;

@end

#endif
