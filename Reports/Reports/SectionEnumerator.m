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

#import "SectionEnumerator.h"
#import "AppDelegate.h"
#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqQuery.h"
#import "RptqQueryGroup.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"

@interface SectionEnumerator ()

@property (nonatomic, strong) RptqDocument *document;

@end

@implementation SectionEnumerator

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
            RptqDocumentSection *section = [RptqDocumentSection documentSectionForRow: current
                                                                                query: query];
            [result addObject:section];
        }
    }
    return result;
}

- (id)nextObject {
    RptqDatabase *database = [[[self document] hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];

    NSInteger current = [self current];
    id result = [RptqDocumentSection documentSectionForRow: current query: query];
    current++;
    [self setCurrent:current];
    return result;
}

@end
