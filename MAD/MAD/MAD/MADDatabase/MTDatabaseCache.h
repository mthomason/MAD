//
//  MTDatabaseCache.h
//  MAD
//
//  Created by Michael Thomason on 7/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseCache_h
#define Reports_MTDatabaseCache_h

#import "MTDatabase.h"
#import <MADFoundation/MADDataType.h>

@interface MTDatabaseCache : MTDatabase

    - (void *)databaseHandle;
    - (BOOL)tableExist:(NSString *)tablename;
    - (NSString *)nativeTypeForDataType:(MTDataType)dataType;
    - (void)beginBulkInsert;
    - (void)endBulkInsert;

@end

#endif
