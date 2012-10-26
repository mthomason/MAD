//
//  NSObject+RptqDocument_Extras.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RptqDocument.h"

@interface RptqDocument (Extras)

+ (void)queryDatabaseFor: (NSManagedObjectContext *)objectContext
              completion: (void (^)(NSArray *results))completion;

+ (RptqDocument *)createMainDocumentForManagedObjectContext:(NSManagedObjectContext *)objectContext;
+ (RptqDocument *)getMainDocumentForManagedObjectContext:(NSManagedObjectContext *)objectContext;

@end