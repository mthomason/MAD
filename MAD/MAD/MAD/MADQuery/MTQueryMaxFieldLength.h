//
//  MTQueryMaxFieldLength.h
//  MAD
//
//  Created by Michael Thomason on 4/1/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryMaxFieldLength_h
#define Reports_MTQueryMaxFieldLength_h

#import "MTQuery.h"

@interface MTQueryMaxFieldLength : MTQuery
    <MADQueryFieldKeysProtocol>

    - (NSString *)getSql:(NSError * __autoreleasing *)error;

@end

#endif
