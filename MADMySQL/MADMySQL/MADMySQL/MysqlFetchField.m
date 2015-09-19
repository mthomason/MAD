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

@implementation MysqlFetchField

@synthesize name,fieldType,width,primaryKey,decimals;

@end
