//
//  MADDatabaseResultValue.h
//  MADSqlite3
//
//  Created by Michael on 5/8/25.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADSqlite3_MADDatabaseResultValue_h
#define MADSqlite3_MADDatabaseResultValue_h

#import <Foundation/Foundation.h>
#import <MADFoundation/MADDataType.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADDatabaseResultValue : NSObject <NSCopying>

+ (instancetype)newDatabaseResultValue:(void *)statement columnNumber:(int)columnNumber;
+ (instancetype)newDatabaseResultValueCast: (void * /* sqlite3_stmt * */)statement
						   forColumnNumber: (int)columnCounter
								  withType: (MADDataType)type;

@end

NS_ASSUME_NONNULL_END

#endif
