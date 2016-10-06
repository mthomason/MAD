//
//  MysqlFetchField.m
//  mysql_connector
//
//  Created by Karl Kraft on 10/22/09.
//  Copyright 2009-2011 Karl Kraft. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MysqlFetchField.h"
#import <mysql.h>
#import <Foundation/NSString.h>

@implementation MysqlFetchField

- (instancetype)initWithField:(MYSQL_FIELD)field fieldName:(NSString *)fieldName {
    if (self = [super init]) {
        _name = fieldName.copy;
        _width = field.length;
        _decimals = field.decimals;
        _fieldType = field.type;
        if (IS_PRI_KEY(field.flags)) _primaryKey = YES;
    }
    return self;
}

@end
