//
//  MADMySQLIndex.m
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMySQLIndex.h"

#import "MADMySQLConnection.h"

@interface MADMySQLIndex ()

	@property(nonatomic, strong, readwrite) MADMySQLConnection *connection;

@end

@implementation MADMySQLIndex

+ (MADMySQLIndex *)indexWithConnection:(MADMySQLConnection *)aConnection {
	MADMySQLIndex *index = [[self alloc] init];
	index.connection = aConnection;
	return index;
}

@end
