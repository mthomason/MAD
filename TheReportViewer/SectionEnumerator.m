//
//  SectionEnumerator.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/14/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "SectionEnumerator.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqQueryGroup.h"
#import "UIManagedDocumentQuery.h"

@implementation SectionEnumerator

@synthesize managedDocumentQuery = _managedDocumentQuery;
@synthesize total = _total, current = _current;

- (void)dealloc {
    [_managedDocumentQuery release];
    [super dealloc];
}

- (id)initWithManagedDocumentQuery:(UIManagedDocumentQuery *)managedDocument {
    self = [super init];
    if (self) {
        [self setManagedDocumentQuery: managedDocument];
        [self setCurrent: 0];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"weight" ascending:YES];
        request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSError *error = nil;
        NSArray *groups = [[[[self managedDocumentQuery] managedObjectContext] executeFetchRequest:request error:&error] retain];
        [self setTotal: (error) ? 0 : [groups count]];
        [groups release];
    }
    return self;
}

- (NSInteger)count {
    return [self total];
}

- (NSArray *)allObjects {
    NSMutableArray *result = [[NSMutableArray alloc]initWithCapacity:([self total] - [self current])];
    for (; [self current]<[self total]; self.current++) {
        [result addObject:[RptqDocumentSection getDocumentSectionForRow: [self current]
                                                forManagedObjectContext: [[self managedDocumentQuery] managedObjectContext]]];
    }
    return [result autorelease];
}

- (id)nextObject {
    return [RptqDocumentSection getDocumentSectionForRow: self.current++
                                 forManagedObjectContext: [[self managedDocumentQuery] managedObjectContext]];
}

@end