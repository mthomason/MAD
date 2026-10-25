//
//  MADDatabase+Constructor.h
//  MAD
//
//  Created by Michael on 8/28/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTDatabase_Constructor_h
#define Reports_MTDatabase_Constructor_h

#import <MADAPI/MADDatabase.h>

@interface MADDatabase (Constructor)

+ (instancetype)newDatabaseWithConnection:(MADDatabaseConnection *)connection;

@end

#endif
