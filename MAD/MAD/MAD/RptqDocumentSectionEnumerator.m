//
//  SectionEnumerator.m
//  Reports
//
//  Created by Michael Thomason on 2/14/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocumentSectionEnumerator.h"
#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqQuery.h"
#import "RptqQuery+Extras.h"
#import "RptqQueryGroup.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectID.h>

@interface RptqDocumentSectionEnumerator ()

    @property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
    @property (nonatomic, copy) NSManagedObjectID *documentObjectID;

@end

@implementation RptqDocumentSectionEnumerator

- (id)initWithDocument:(RptqDocument *)document {
    if (self = [super init]) {
        _documentObjectID = document.objectID.copy;
        self.managedObjectContext = document.managedObjectContext;
        self.current = 0;
    }
    return self;
}

- (NSUInteger)count {
    RptqDocument *document = (RptqDocument *)[self.managedObjectContext objectWithID:self.documentObjectID];
    RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
    RptqQuery *query = database.hasQueries.anyObject;
    return [query sectionCount];
}

- (NSArray *)allObjects {
    RptqDocument *document = (RptqDocument *)[self.managedObjectContext objectWithID:self.documentObjectID];
    RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
    RptqQuery *query = database.hasQueries.anyObject;
    NSUInteger current = self.current;
    NSUInteger total = [self count];
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:(total - current)];
    for (; self.current<total; self.current++) {
        @autoreleasepool {
            RptqDocumentSection *section = [query documentSectionForSelectedIndex: current];
            [result addObject:section];
        }
    }
    return result;
}

- (id)nextObject {
    RptqDocument *document = (RptqDocument *)[self.managedObjectContext objectWithID:self.documentObjectID];
    RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
    RptqQuery *query = database.hasQueries.anyObject;

    NSUInteger current = self.current;
    id result = [query documentSectionForSelectedIndex: current];
    current++;
    self.current = current;
    return result;
}

@end
