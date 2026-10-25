//
//  MADMySQLFetchField.h
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADMySQLFetchField_h
#define MAD_MADMySQLFetchField_h

#import <Foundation/NSObject.h>
#import <mysql.h>

/*
	One result-set column, captured from a MYSQL_FIELD: the name, the
	MYSQL_TYPE_* code, the display width and decimals, and whether it is part
	of the primary key.
 */
@interface MADMySQLFetchField : NSObject

	@property(nonatomic, copy) NSString *name;
	@property(nonatomic, assign) NSInteger fieldType;
	@property(nonatomic, assign) NSUInteger width;
	@property(nonatomic, assign) NSUInteger decimals;
	@property(nonatomic, assign) BOOL primaryKey;

	- (instancetype)initWithField:(MYSQL_FIELD)field fieldName:(NSString *)fieldName;

@end

#endif
