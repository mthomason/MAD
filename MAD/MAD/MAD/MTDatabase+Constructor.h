//
//  MTDatabase+Constructor.h
//  MAD
//
//  Created by Michael on 8/28/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabase_Constructor_h
#define Reports_MTDatabase_Constructor_h

#import <MADAPI/MTDatabase.h>

@interface MTDatabase (Constructor)

    + (instancetype)newDatabaseWithConnection:(MADDatabaseConnection *)connection;

@end

#endif
