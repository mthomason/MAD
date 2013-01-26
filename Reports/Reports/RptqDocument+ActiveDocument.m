//
//  RptqDocument+ActiveDocument.m
//  Reports
//
//  Created by Michael Thomason on 1/22/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocument+ActiveDocument.h"

@implementation RptqDocument (ActiveDocument)

+ (NSString *)sqlStatementForActiveDocument {
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    return [RptqQuery getSqlForQuery:query];
}

@end