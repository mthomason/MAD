//
//  RptqDatabaseCredentals+MADDatabaseConnection.h
//  MAD
//
//  Created by Michael on 1/12/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqUserCredentals_MADDatabaseConnection_h
#define Reports_RptqUserCredentals_MADDatabaseConnection_h

#import <MADAPI/MADDatabaseType.h>

#import <MAD/RptqDatabaseCredentals.h>

@interface RptqDatabaseCredentals (MADDatabaseConnection)

    - (MADDatabaseType)databaseType;

@end

#endif
