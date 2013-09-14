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
#import "Constants.h"

@interface MTDatabaseConnection : NSObject

@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) NSString *server;
@property (nonatomic, retain) NSString *database;
@property (nonatomic, retain) NSString *host;
@property (nonatomic, assign) NSInteger port;

- (NSString *)appname;

@end

#endif
