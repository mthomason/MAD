//
//  RptqQueryTables+Extras.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryTables.h"
#import "RptqTable.h"
#import "UIManagedDocumentReport.h"
#import "RptqDocument+Extras.h"

@interface RptqQueryTables (Extras)

+ (NSArray *)namesForManagedObjectContext:(NSManagedObjectContext *)objectContext;
+ (NSInteger)countForManagedObjectContext:(NSManagedObjectContext *)objectContext;
+ (void)deleteTable:(NSManagedObjectID *)objid fromManagedObjectContext:(NSManagedObjectContext *)moc;
+ (RptqQueryTables *)createAndInsertQueryTableFor:(RptqTable *)table inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end