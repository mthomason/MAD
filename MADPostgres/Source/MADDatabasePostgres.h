//
//  MADDatabasePostgres.h
//  MADPostgres
//
//  Created by Michael Thomason on 10/28/26.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADDatabasePostgres_h
#define MADDatabasePostgres_h

#import <Foundation/Foundation.h>
#import <MADFoundation/MADDataType.h>
#import <MADAPI/MADDatabase.h>

@class MADDataTable;

@interface MADDatabasePostgres : MADDatabase

+ (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
+ (MADSafeQueryField *)newSafeIdentifier:(NSString *)fieldOrTableName;
- (NSString *)queryKey:(NSString *)fieldName table:(NSString *)tableName;
- (MADSafeQueryField *)newSafeIdentifier:(NSString *)fieldOrTableName;
- (NSString *)identifier;

+ (id)objectValueForCString:(const char *)cStr
					 isNull:(BOOL)isNull
				   dataType:(MADDataType)dataType;

@end

#endif /* MADDatabasePostgres_h */
