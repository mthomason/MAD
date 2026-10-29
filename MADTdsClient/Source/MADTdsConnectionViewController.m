//
//  MADConnectionViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADTdsConnectionViewController.h"

#if TARGET_OS_IPHONE
#import "MADDatabaseConnectionSQLServer.h"

@implementation MADTdsConnectionViewController

#pragma mark -
#pragma mark Override Points

- (MADDatabaseConnection *)databaseConnection {
	return [[MADDatabaseConnectionSQLServer alloc] initWithHost: self.textFieldHost.text
														 server: self.textFieldHost.text
													   database: self.textFieldDatabase.text
														andPort: self.textFieldPort.text.integerValue];
}

- (NSString *)displayName {
	return @"SQL Server / TDS";
}

- (void)resetInterface {
	[super resetInterface];
}

- (void)enableUserInteraction {
	[super enableUserInteraction];
}

@end
#endif
