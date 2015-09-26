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
#import <MADFileManager/MADFileManager.h>
#import <MADDataStructures/MADDataStructures.h>
#import <MADSqlite3/MADSqlite3.h>
#import <MADFoundation/MTDataTable.h>
#import <MADFoundation/MTDataColumn.h>

@interface MTDataTableFast : MTDataTable
    <NSCoding, NSFastEnumeration>

@end

#endif
