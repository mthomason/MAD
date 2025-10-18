//
//  MADDatabase+Constructor.h
//  MAD
//
//  Created by Michael on 8/28/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTDatabase_Constructor_h
#define Reports_MTDatabase_Constructor_h

#import <MADAPI/MADDatabase.h>

@interface MADDatabase (Constructor)

+ (instancetype)newDatabaseWithConnection:(MADDatabaseConnection *)connection;

@end

#endif
