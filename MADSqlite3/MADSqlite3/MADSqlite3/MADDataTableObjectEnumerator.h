//
//  MADDataTableObjectEnumerator.h
//  MAD
//
//  Created by Michael Thomason on 4/21/14.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef MADSqlite3_MADDataTableObjectEnumerator_h
#define MADSqlite3_MADDataTableObjectEnumerator_h

#import <Foundation/NSEnumerator.h>

@class MADDatabaseConnection, MADQuery, MADDataColumn;

@interface MADDataTableObjectEnumerator : NSEnumerator

- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)databaseConnection
								   columns:(NSDictionary <NSString *, MADDataColumn *> *)columns
								columnKeys:(NSArray <NSString *> *)columnKeys
									 query:(MADQuery *)query;

@end

#endif
