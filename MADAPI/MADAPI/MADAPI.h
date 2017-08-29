//
//  MADAPI.h
//  MADAPI
//
//  Created by Michael on 8/28/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/NSObjCRuntime.h>

//! Project version number for MADAPI.
FOUNDATION_EXPORT double MADAPIVersionNumber;

//! Project version string for MADAPI.
FOUNDATION_EXPORT const unsigned char MADAPIVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <MADAPI/PublicHeader.h>

#import <MADAPI/MADDatabaseProtocol.h>
#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADDatabaseType.h>
#import <MADAPI/MTDatabase.h>
#import <MADAPI/MADNotificationDidReadRows.h>
#import <MADAPI/MADDatabaseConnection.h>

#import <MADAPI/MADDatabaseTable.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADAPI/MADDatabaseDataBinding.h>
#import <MADAPI/MADDatabaseCacheProtocol.h>
