//
//  MysqlException.h
//  mysql_connector
//
//  Created by Karl Kraft on 6/19/09.
//  Copyright 2009-2010 Karl Kraft. All rights reserved.
//

#ifndef MAD_MysqlException_h
#define MAD_MysqlException_h

#import <Foundation/Foundation.h>

@class MysqlConnection;

@interface MysqlException : NSException

    + (void)raiseConnection:(MysqlConnection *)aConnection withFormat:(NSString *)format,...  __attribute__ ((noreturn));;
    + (NSError *)errorWithConnection:(MysqlConnection *)connection domain:(NSString *)domain andCode:(NSInteger)code;

@end

#endif

//#define MYSQL_LOGGING

#ifdef MYSQL_LOGGING
#define MysqlLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] );
#else
#define MysqlLog(x...)
#endif
