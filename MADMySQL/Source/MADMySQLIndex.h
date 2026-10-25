//
//  MADMySQLIndex.h
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADMySQLIndex_h
#define MAD_MADMySQLIndex_h

#import <Foundation/NSObject.h>

@class MADMySQLConnection;

/*
	A bare handle to a connection, carried by the index-management code paths.
 */
@interface MADMySQLIndex : NSObject

	@property(nonatomic, readonly) MADMySQLConnection *connection;

	+ (MADMySQLIndex *)indexWithConnection:(MADMySQLConnection *)aConnection;

@end

#endif
