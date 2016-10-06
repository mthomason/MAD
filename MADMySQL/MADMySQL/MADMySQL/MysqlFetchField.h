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

    @property(copy) NSString *name;
    @property(assign) NSInteger fieldType;
    @property(assign) NSUInteger width;
    @property(assign) NSUInteger decimals;
    @property(assign) BOOL primaryKey;

    - (instancetype)initWithField:(MYSQL_FIELD)field fieldName:(NSString *)fieldName;

@end

#endif
