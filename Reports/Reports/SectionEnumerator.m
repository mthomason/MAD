//
//  SectionEnumerator.m
//  Reports
//
//  Created by Michael Thomason on 2/14/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "SectionEnumerator.h"
#import "AppDelegate.h"

@interface SectionEnumerator ()

//@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@end

@implementation SectionEnumerator

- (void)dealloc {
    [super dealloc];
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    self = [super init];
    if (self) {
        MTLog(@"Alloc");
        MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
        NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
        RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext:managedObjectContext];
        RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
        RptqQuery *query = [[database hasQueries] anyObject];
        [self setCurrent: 0];
        [self setTotal: [[query hasQueryGroups] count]];
        [activeDocument release];
    }
    return self;
}

- (NSInteger)count {
    return [self total];
}

- (NSArray *)allObjects {
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext:managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    
    NSInteger current = [self current];
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:([self total] - current)];
    for (; [self current]<[self total]; self.current++) {
        @autoreleasepool {
            RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForRow: current
                                                                                forQuery: query];
            [result addObject:section];
        }
    }
    [activeDocument release];
    return [result autorelease];
}

- (id)nextObject {
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext:managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];

    NSInteger current = [self current];
    id result = [RptqDocumentSection getDocumentSectionForRow: current forQuery: query];
    current++;
    [self setCurrent:current];
    [activeDocument release];
    return result;
}

@end
