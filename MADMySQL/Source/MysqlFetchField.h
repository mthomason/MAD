//
//  MysqlFetchField.h
//  mysql_connector
//
//  Created by Karl Kraft on 10/22/09.
//  Copyright 2009-2011 Karl Kraft. All rights reserved.
//

#ifndef MAD_MysqlFetchField_h
#define MAD_MysqlFetchField_h

#import <Foundation/NSObject.h>
#import <mysql.h>

@interface MysqlFetchField : NSObject

	@property(nonatomic, copy) NSString *name;
	@property(nonatomic, assign) NSInteger fieldType;
	@property(nonatomic, assign) NSUInteger width;
	@property(nonatomic, assign) NSUInteger decimals;
	@property(nonatomic, assign) BOOL primaryKey;

	- (instancetype)initWithField:(MYSQL_FIELD)field fieldName:(NSString *)fieldName;

@end

#endif
