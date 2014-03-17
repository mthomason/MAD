//
//  SectionEnumerator.m
//  Reports
//
//  Created by Michael Thomason on 2/14/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "SectionEnumerator.h"
#import "AppDelegate.h"

@interface SectionEnumerator ()

@property (nonatomic, retain) RptqDocument *document;

@end

@implementation SectionEnumerator

- (void)dealloc {
    [_document release];
    [super dealloc];
}

- (id)initWithDocument:(RptqDocument *)document {
    self = [super init];
    if (self) {
        RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
        RptqQuery *query = [[database hasQueries] anyObject];
        [self setCurrent: 0];
        [self setTotal: [[query hasQueryGroups] count]];
        [self setDocument:document];
    }
    return self;
}

- (NSInteger)count {
    return [self total];
}

- (NSArray *)allObjects {
    RptqDatabase *database = [[[self document] hasDatabaseSchemas] anyObject];
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
    return [result autorelease];
}

- (id)nextObject {
    RptqDatabase *database = [[[self document] hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];

    NSInteger current = [self current];
    id result = [RptqDocumentSection getDocumentSectionForRow: current forQuery: query];
    current++;
    [self setCurrent:current];
    return result;
}

@end
