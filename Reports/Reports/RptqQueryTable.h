//
//  RptqQueryTable.h
//  Reports
//
//  Created by Michael Thomason on 3/12/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabaseSchemaTable;

@interface RptqQueryTable : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) RptqDatabaseSchemaTable *fromDatabaseSchemaTable;

@end
