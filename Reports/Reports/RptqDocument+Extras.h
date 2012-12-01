//
//  NSObject+RptqDocument_Extras.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RptqDocument.h"
#import <CoreData/CoreData.h>
#import "Constants.h"
#import "RptqQuery.h"
#import "RptqDocumentSection+Extras.h"
#import "MNSDatabaseSalesForce.h"
#import "MNSDatabaseMySql.h"

#import "RptqDatabase+Extras.h"
#import "RptqUserCredentals+Extras.h"
#import "RptqTable+Extras.h"
#import "RptqField+Extras.h"

@interface RptqDocument (Extras)

+ (void)queryDatabaseFor: (NSManagedObjectContext *)objectContext
              completion: (void (^)(NSArray *results))completion;

+ (RptqDocument *)createMainDocumentForManagedObjectContext:(NSManagedObjectContext *)objectContext;
+ (RptqDocument *)getMainDocumentForManagedObjectContext:(NSManagedObjectContext *)objectContext;

+ (void)addDatabase: (MNSDatabase *)database ToMainDocumentForManagedObjectContext:(NSManagedObjectContext *)objectContext
         completion: (void (^)(BOOL success))completion;

@end