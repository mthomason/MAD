//
//  RptqQueryGroup+Extras.h
//  TheReportViewer
//
//  Created by Michael Thomason on 3/7/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryGroup+Extras.h"

@implementation RptqQueryGroup (Extras)

- (void)awakeFromInsert {
    [super awakeFromInsert];
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flag {
    [super awakeFromSnapshotEvents:flag];
}

+ (NSInteger)numberOfGroupsForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
    NSError *error = nil;
    NSInteger result = [objectContext countForFetchRequest:request error:&error];
    return (error) ? 0 : result;
}

// MARK: Creating group. Updates document sections to reflect new group.
+ (RptqQueryGroup *)createAndInsertQueryGroupFor:(RptqField *)field  andSort:(MNSSortOrder)sortOrder inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];

    NSEntityDescription *entityDescriptionQueryGroup = [NSEntityDescription entityForName:NSStringFromClass([RptqQueryGroup class])
                                                                   inManagedObjectContext:managedObjectContext];
    NSEntityDescription *entityDescriptionDocumentSection = [NSEntityDescription entityForName:NSStringFromClass([RptqDocumentSection class])
                                                                        inManagedObjectContext:managedObjectContext];

    RptqQueryGroup *queryGroup = [[RptqQueryGroup alloc] initWithEntity:entityDescriptionQueryGroup
                                         insertIntoManagedObjectContext:managedObjectContext];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
    NSError *error = nil;
    NSInteger groupCount = [managedObjectContext countForFetchRequest:request error:&error];
    groupCount = (error) ? 0 : groupCount;
    
    [queryGroup setHasField:field];
    [queryGroup setField:[field name]];
    [queryGroup setTable:[[field inTable] name]];
    [queryGroup setSort:[NSNumber numberWithInteger:sortOrder]];
    [queryGroup setWeight:[NSNumber numberWithInteger: (groupCount - 1)]];
    
    RptqDocumentSection *dsHeader = [[RptqDocumentSection alloc] initWithEntity:entityDescriptionDocumentSection insertIntoManagedObjectContext:managedObjectContext];
    [dsHeader setType: [NSNumber numberWithInteger: MNSDocumentSectionTypeGroupHeader]];
    [queryGroup addHasSectionObject:dsHeader];
    [dsHeader release];
  
    RptqDocumentSection *dsFooter = [[RptqDocumentSection alloc] initWithEntity:entityDescriptionDocumentSection insertIntoManagedObjectContext:managedObjectContext];
    [dsFooter setType: [NSNumber numberWithInteger:MNSDocumentSectionTypeGroupFooter]];
    [queryGroup addHasSectionObject:dsFooter];
    [dsFooter release];
    
    //RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    //RptqQuery *query = [[database hasQueries] anyObject];
    //[query addHasQueryGroupsObject: queryGroup];
    NSLog(@"QueryGroup: %@", queryGroup);
    return [queryGroup autorelease];

}

- (NSString *)fieldNameNice {
    return [[NSString stringWithFormat:@"%@.%@", [self table], [self field]] lowercaseString];
}

- (NSString *)sortDisplayNice {
    NSString *sort;
    MNSSortOrder sortOrder = [[self sort] integerValue];
    switch (sortOrder) {
        case MNSSortOrderAccending:
            sort = @"accending";
            break;
        case MNSSortOrderDecending:
            sort = @"decending";
            break;
        default:
            sort = @"";
            break;
    }
    return [sort lowercaseString];
}

@end