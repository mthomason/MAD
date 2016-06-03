//
//  NSString+MysqlEscape.m
//  mysql_connector
//
//  Created by Karl Kraft on 6/12/08.
//  Copyright 2008-2013 Karl Kraft. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "NSString+MysqlEscape.h"
#import "MysqlConnection.h"
#import <string.h>
#import "mysql.h"

@implementation NSString(MysqlEscape)

- (NSString *)mysqlEscapeInConnection:(MysqlConnection *)connection {
    const char *ch = self.UTF8String;
    char *buf=malloc(strlen(ch)*2+1);
    mysql_real_escape_string(connection.connection, buf, ch, strlen(ch));
    NSString *retval=@(buf);
    free(buf);
    return retval;
}

@end
