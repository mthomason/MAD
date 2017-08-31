//
//  MTQueryMaxFieldLength.h
//  MAD
//
//  Created by Michael Thomason on 4/1/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryMaxFieldLength_h
#define Reports_MTQueryMaxFieldLength_h

#import <MADAPI/MADQuery.h>

@interface MTQueryMaxFieldLength : MADQuery
    <MADQueryFieldKeysProtocol, MADQueryDatabaseProtocol>

    - (NSString *)getSql:(NSError * __autoreleasing *)error;

@end

#endif
