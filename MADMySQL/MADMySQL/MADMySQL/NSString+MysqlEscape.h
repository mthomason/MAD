//
//  NSString+MysqlEscape.h
//  mysql_connector
//
//  Created by Karl Kraft on 6/12/08.
//  Copyright 2008-2013 Karl Kraft. All rights reserved.
//

#ifndef MAD_NSString_MysqlEscape_h
#define MAD_NSString_MysqlEscape_h

@interface NSString(MysqlEscape)

- (NSString *)mysqlEscapeInConnection:(MysqlConnection *)connection;

@end

#endif
