//
//  MADQueryCacheSelectGroupKeys.h
//  MAD
//
//  Created by Michael Thomason on 5/21/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTQueryCacheSelectGroupKeys_h
#define Reports_MTQueryCacheSelectGroupKeys_h

#import <MADAPI/MADQuery.h>

// Adopts MADQueryDatabaseProtocol so -[MADQuery getSql:database:error:] hands it the
// database it is about to run against.  The predicate values have to be quoted the way
// that database reads them, and it is the only way to learn which one that is.
@interface MADQueryCacheSelectGroupKeys : MADQuery <MADQueryDatabaseProtocol>

@end

#endif
