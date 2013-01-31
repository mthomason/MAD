//
//  SectionEnumerator.m
//  TheReportViewer
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
        [self setManagedObjectContext:managedObjectContext];
        [self setCurrent: 0];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"weight" ascending:YES];
        request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSError *error = nil;
        NSArray *groups = [[[self managedObjectContext] executeFetchRequest:request error:&error] retain];
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
                                                forManagedObjectContext: [self managedObjectContext]]];
    }
    return [result autorelease];
}

- (id)nextObject {
    return [RptqDocumentSection getDocumentSectionForRow: self.current++
                                 forManagedObjectContext: [self managedObjectContext]];
}

@end