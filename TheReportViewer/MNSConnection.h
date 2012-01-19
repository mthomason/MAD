//
//  NSConnection.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "mysql.h"

@interface MNSConnection : NSObject {
@public
    MYSQL conn;
}

@end
