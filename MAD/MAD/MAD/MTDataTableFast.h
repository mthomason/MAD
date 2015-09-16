//
//  MTDataTableFast.h
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDataTableFast_h
#define Reports_MTDataTableFast_h

#import <Foundation/Foundation.h>
#import <MADSqlite3/MADSqlite3.h>
#import <MADFileManager/MADFileManager.h>
#import <MADCocoaExtensions/MADCocoaExtensions.h>
#import "MTDataTableFastObjectEnumerator.h"
#import "MTDatabaseSqlite3.h"
#import "MTDatabaseConnectionSqlite3.h"
#import "MTDataTable.h"

@interface MTDataTableFast : MTDataTable
    <NSCoding, NSFastEnumeration>

@end

#endif
