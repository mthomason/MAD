//
//  MADConnectionViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADMySQLConnectionViewController.h"
#import "MADDatabaseConnectionMySql.h"

@implementation MADMySQLConnectionViewController

#pragma mark -
#pragma mark Override Points

- (MADDatabaseConnection *)databaseConnection {
    MADDatabaseConnectionMySql *databaseConnection;
    databaseConnection = [[MADDatabaseConnectionMySql alloc] initWithHost: self.textFieldHost.text
                                                                 database: self.textFieldDatabase.text
                                                                  andPort: self.textFieldPort.text.integerValue];
    return databaseConnection;
}

- (NSString *)displayName {
    return @"MySQL";
}

- (void)resetInterface {
    [super resetInterface];
}

- (void)enableUserInteraction {
    [super enableUserInteraction];
}

@end
