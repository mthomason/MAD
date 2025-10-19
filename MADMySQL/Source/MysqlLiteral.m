//
//  MysqlLiteral.m
//  mysql_connector
//
//  Created by Karl Kraft on 8/29/09.
//  Copyright 2009-2012 Karl Kraft. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MysqlLiteral.h"
#import <Foundation/NSString.h>

@implementation MysqlLiteral

+ (MysqlLiteral *)literalWithString:(NSString *)s {

	MysqlLiteral *newObject = [[self alloc] init];
	newObject->_string= [s copy];
	return newObject;

}

@end
