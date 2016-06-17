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
#import "RptqQuery+Extras.h"
#import "RptqQueryGroup.h"
#import "RptqDocumentSection+Extras.h"
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectID.h>

@interface RptqDocumentSectionEnumerator ()

    @property (nonatomic, assign)   NSManagedObjectContext *managedObjectContext;
    @property (nonatomic, copy)     NSManagedObjectID *queryObjectID;

@end

@implementation RptqDocumentSectionEnumerator

- (id)initWithDocument:(RptqDocument *)document {
    if (self = [super init]) {
        RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
        RptqQuery *query = database.hasQueries.anyObject;
        _queryObjectID = query.objectID.copy;
        self.managedObjectContext = document.managedObjectContext;
        self.current = 0;
    }
    return self;
}

- (NSUInteger)count {
    RptqQuery *query = [self.managedObjectContext objectWithID:_queryObjectID];
    return [query sectionCount];
}

- (NSArray *)allObjects {
    RptqQuery *query = [self.managedObjectContext objectWithID:_queryObjectID];
    NSUInteger total = [self count];
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:(total - _current)];
    for (; _current<total; _current++) {
        @autoreleasepool {
            RptqDocumentSection *section = [query documentSectionForSelectedIndex: _current];
            [result addObject:section];
        }
    }
    return result;
}

- (id)nextObject {
    RptqQuery *query = [self.managedObjectContext objectWithID:_queryObjectID];
    id result = [query documentSectionForSelectedIndex: _current];
    _current++;
    return result;
}

@end
