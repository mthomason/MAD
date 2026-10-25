//
//  MNSDatabaseMySql.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTDatabaseMySql_h
#define Reports_MTDatabaseMySql_h

#import <MADAPI/MADDatabase.h>
#import <MADFoundation/MADDataType.h>

@interface MADDatabaseMySQL : MADDatabase

	+ (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
	- (NSString *)queryKey:(NSString *)fieldName table:(NSString *)tableName;
	- (MADSafeQueryField *)newSafeIdentifier:(NSString *)fieldOrTableName;

	- (NSString *)identifier;

@end

#endif
