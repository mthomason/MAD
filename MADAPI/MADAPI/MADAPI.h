//
//  MADAPI.h
//  MADAPI
//
//  Created by Michael on 8/28/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/NSObjCRuntime.h>

FOUNDATION_EXPORT double MADAPIVersionNumber;
FOUNDATION_EXPORT const unsigned char MADAPIVersionString[];

#import <MADAPI/MADConnectionViewController.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseConnection.h>

#import <MADAPI/MADConnectionSQLGenericViewController.h>

#import <MADAPI/MADViewControllerStandardProtocol.h>

#import <MADAPI/MADDatabaseProtocol.h>
#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADDatabaseCacheProtocol.h>
#import <MADAPI/MADDatabaseConnectionsPropertiesURLProtocol.h>

#import <MADAPI/MADDatabaseType.h>
#import <MADAPI/MADNotificationDidReadRows.h>

#import <MADAPI/MADDatabaseTable.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADAPI/MADDatabaseDataBinding.h>

#import <MADAPI/MADQuery.h>
#import <MADAPI/MADQueryType.h>

#import <MADAPI/MADConnectionsPropertiesProtocol.h>
#import <MADAPI/MADErrorContainer.h>
