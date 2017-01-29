//
//  RptqUserCredentals+MADDatabaseConnection.h
//  MAD
//
//  Created by Michael on 1/12/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqUserCredentals_MADDatabaseConnection_h
#define Reports_RptqUserCredentals_MADDatabaseConnection_h

#import <RptqUserCredentals+CoreDataClass.h>
#import <MAD/MADDatabaseConnection.h>

@interface RptqUserCredentals (MADDatabaseConnection)

    - (MADDatabaseType)databaseType;

@end

#endif
