//
//  MADQuerySampleDataTableRange.h
//  MAD
//
//  Created by Michael Thomason on 7/11/25.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADQuerySampleDataTableRange_h
#define Reports_MADQuerySampleDataTableRange_h

#import <MADAPI/MADQuery.h>

@interface MADQuerySampleDataTableRange : MADQuery <MADQueryFieldKeysProtocol, MADQueryDataTableProtocol, MADQueryDatabaseProtocol, MADQueryDatabaseProtocol, MADQueryCredentialProtocol, MADQueryDatabaseRangeProtocol>

@property (nonatomic, assign) NSUInteger limit;
@property (nonatomic, assign) NSUInteger offset;

- (NSString *)getSql:(NSError * __autoreleasing *)error;

@end

#endif
