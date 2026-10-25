//
//  MADDataTableSingleColumnEnumerator.h
//  MADSqlite3
//
//  Created by Michael on 5/9/25.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADSqlite3_MADDataTableSingleColumnEnumerator_h
#define MADSqlite3_MADDataTableSingleColumnEnumerator_h

#import <Foundation/NSEnumerator.h>
#import <Foundation/NSObject.h>

@class MADDatabaseConnection, MADQuery, MADDataColumn;

NS_ASSUME_NONNULL_BEGIN

@interface MADDataTableSingleColumnEnumerator : NSEnumerator<__kindof NSObject <NSCopying, NSSecureCoding> *>

- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)databaseConnection
								   columns:(NSDictionary <NSString *, MADDataColumn *> *)columns
								columnKeys:(NSArray <NSString *> *)columnKeys
									 query:(MADQuery *)query;

@end

NS_ASSUME_NONNULL_END

#endif
