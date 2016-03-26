//
//  MysqlIndex.h
//  mysql_connector
//
//  Created by Bill Allen on 8/26/11.
//  Copyright 2011 Karl Kraft. All rights reserved.
//

#ifndef MAD_MysqlIndex_h
#define MAD_MysqlIndex_h

#import <Foundation/NSObject.h>

@class MysqlConnection;

@interface MysqlIndex : NSObject {
    MysqlConnection *connection;
}

    @property(readonly)MysqlConnection *connection;
    + (MysqlIndex *)indexWithConnection:(MysqlConnection *)aConnection;

@end

#endif
