//
//  RptqQueryTables+Extras.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryTables.h"

@interface RptqQueryTables (Extras)

+ (NSArray *)namesForManagedObjectContext:(NSManagedObjectContext *)objectContext;
+ (void)deleteTable:(NSManagedObjectID *)objid fromManagedObjectContext:(NSManagedObjectContext *)moc;

@end