//
//  MADQueryMaxFieldLength.h
//  MAD
//
//  Created by Michael Thomason on 4/1/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTQueryMaxFieldLength_h
#define Reports_MTQueryMaxFieldLength_h

#import <MADAPI/MADQuery.h>

@interface MADQueryMaxFieldLength : MADQuery <MADQueryFieldKeysProtocol, MADQueryDatabaseProtocol>

- (NSString *)getSql:(NSError * __autoreleasing *)error;

@end

#endif
