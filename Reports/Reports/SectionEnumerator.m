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

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@end

@implementation SectionEnumerator

- (void)dealloc {
    [_managedObjectContext release];
    [super dealloc];
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    self = [super init];
    if (self) {
        RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext:managedObjectContext];
        RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
        RptqQuery *query = [[database hasQueries] anyObject];
        [self setManagedObjectContext:managedObjectContext];
        [self setCurrent: 0];
        [self setTotal: [[query hasQueryGroups] count]];
    }
    return self;
}

- (NSInteger)count {
    return [self total];
}

- (NSArray *)allObjects {
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext:[self managedObjectContext]];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    
    NSMutableArray *result = [[NSMutableArray alloc]initWithCapacity:([self total] - [self current])];
    for (; [self current]<[self total]; self.current++) {
        RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForRow: [self current]
                                                                            forQuery: query];

        [result addObject:section];
    }
    return [result autorelease];
}

- (id)nextObject {
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext:[self managedObjectContext]];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];

    id result = [RptqDocumentSection getDocumentSectionForRow: self.current
                                                forQuery: query];
    self.current++;
    return result;
}

@end
