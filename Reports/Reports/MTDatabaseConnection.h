//
//  MNSDatabaseConnection.h
//  Reports
//
//  Created by Michael Thomason on 11/23/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseConnection_h
#define Reports_MTDatabaseConnection_h

#import <Foundation/Foundation.h>

@interface MTDatabaseConnection : NSObject

@property (copy) NSString *username;
@property (copy) NSString *password;
@property (copy) NSString *server;
@property (copy) NSString *database;
@property (assign) NSInteger port;

@end

#endif
