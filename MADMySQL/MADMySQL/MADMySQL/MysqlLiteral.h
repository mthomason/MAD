//
//  MysqlLiteral.h
//  mysql_connector
//
//  Created by Karl Kraft on 8/29/09.
//  Copyright 2009-2010 Karl Kraft. All rights reserved.
//

#ifndef MAD_MysqlLiteral_h
#define MAD_MysqlLiteral_h

#import <Foundation/Foundation.h>

@interface MysqlLiteral : NSObject {
    NSString *string;
}

@property(readonly) NSString *string;

+(MysqlLiteral *)literalWithString:(NSString *)s;

@end

#endif
