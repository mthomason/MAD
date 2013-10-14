//
//  NSObject+RptqDocument_Extras.h
//  Reports
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocument_Extras_h
#define Reports_RptqDocument_Extras_h

#import <Foundation/Foundation.h>
#import "RptqDocument.h"
#import <CoreData/CoreData.h>
#import "Constants.h"
#import "RptqQuery.h"
#import "RptqDocumentSection+Extras.h"

//#import "MTDatabaseSalesForce.h"
#import "MTDatabaseMySql.h"
#import "MTDatabaseSqlServer.h"

#import "RptqDatabase+Extras.h"
#import "RptqUserCredentals+Extras.h"
#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDatabaseSchemaField+Extras.h"

@interface RptqDocument (Extras) <MTProtocolCompare>

+ (RptqDocument *)createMainDocumentForManagedObjectContext:(NSManagedObjectContext *)objectContext;
+ (RptqDocument *)getMainDocumentForManagedObjectContext:(NSManagedObjectContext *)objectContext;

+ (void)addDatabase: (MTDatabase *)database toDocument:(RptqDocument *)document
         completion: (void (^)(BOOL success, NSError *error))completion;

@end

#endif
