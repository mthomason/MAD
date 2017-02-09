//
//  MADDatabaseCacheProtocol.h
//  MAD
//
//  Created by Michael Thomason on 7/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDatabaseCacheProtocol_h
#define Reports_MADDatabaseCacheProtocol_h

#import <Foundation/NSObject.h>

@protocol MADDatabaseProtocol;

@protocol MADDatabaseCacheProtocol <NSObject>

    - (id <MADDatabaseProtocol>)delegate;
    - (BOOL)tableExist:(NSString *)tablename;

    - (void)beginBulkInsert;
    - (void)endBulkInsert;

@end

#endif
