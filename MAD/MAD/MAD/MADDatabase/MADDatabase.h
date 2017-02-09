//
//  MADDatabase.h
//  MAD
//
//  Created by Michael on 1/12/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDatabaseTable_h
#define Reports_MADDatabaseTable_h

#import <Foundation/NSObject.h>

@class MADDatabaseConnection;
@class MADDataTable;
@class MADQuery;

@protocol MADDatabaseProtocol
  @required
    - (MADDataTable *)runQuery:(MADQuery *)query;
@end

@interface MADDatabase : NSObject

    + (instancetype)newDatabase:(MADDatabaseConnection *)databaseConnection;

@end

#endif
