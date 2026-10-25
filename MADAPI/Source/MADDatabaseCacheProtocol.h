//
//  MADDatabaseCacheProtocol.h
//  MAD
//
//  Created by Michael Thomason on 7/6/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADDatabaseCacheProtocol_h
#define Reports_MADDatabaseCacheProtocol_h

#import <Foundation/NSObject.h>

@protocol MADDatabaseResultsProtocol;

@protocol MADDatabaseCacheProtocol <NSObject>

	- (id <MADDatabaseResultsProtocol>)delegate;
	- (BOOL)tableExist:(NSString *)tablename;

	- (void)beginBulkInsert;
	- (void)endBulkInsert;

@end

#endif
