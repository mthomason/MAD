//
//  MADPostgresConnectionViewController.m
//  MADPostgres
//
//  Created by Michael Thomason on 10/28/26.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADPostgresConnectionViewController.h"
#import "MADDatabaseConnectionPostgres.h"

@implementation MADPostgresConnectionViewController

#pragma mark -
#pragma mark Override Points

- (MADDatabaseConnection *)databaseConnection {
	return [[MADDatabaseConnectionPostgres alloc] initWithHost:self.textFieldHost.text
													  database:self.textFieldDatabase.text
													   andPort:self.textFieldPort.text.integerValue];
}

- (NSString *)displayName { return @"PostgreSQL"; }

- (void)resetInterface {
	[super resetInterface];
}

- (void)enableUserInteraction {
	[super enableUserInteraction];
}

@end
