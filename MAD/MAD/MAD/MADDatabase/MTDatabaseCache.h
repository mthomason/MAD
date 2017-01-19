//
//  MTDatabaseSqlite3.h
//  MAD
//
//  Created by Michael Thomason on 7/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDatabaseCacheProtocol_h
#define Reports_MADDatabaseCacheProtocol_h

#import "MTDatabase.h"
#import <MADFoundation/MADDataType.h>

@protocol MADDatabaseCacheProtocol <NSObject>
  //@public


    - (id <MTDatabaseProtocol>)delegate;
    - (BOOL)tableExist:(NSString *)tablename;

    - (void)beginBulkInsert;
    - (void)endBulkInsert;

@end

//@interface MTDatabaseSqlite3 : MTDatabase {
//  @public
//    void * /* sqlite3 * */ _database;
//}
//
//    - (id <MTDatabaseProtocol>)delegate;
//    - (BOOL)tableExist:(NSString *)tablename;
//    - (void)beginBulkInsert;
//    - (void)endBulkInsert;
//
//@end

#endif
