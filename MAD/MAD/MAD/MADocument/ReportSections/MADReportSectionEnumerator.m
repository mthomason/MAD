//
//  MADReportSectionEnumerator.m
//  MAD
//
//  Created by Michael Thomason on 6/26/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADReportSectionEnumerator.h"
#import "MADocumentSectionType.h"
#import "MADReportSection.h"
#import "RptqQuery+Extras.h"
#import "RptqDatabase+CoreDataClass.h"
#import "RptqDocument+Extras.h"

@interface MADReportSectionEnumerator ()

    @property (nonatomic, readwrite, strong) RptqQuery *query;
    @property (nonatomic, readwrite, strong) NSMutableArray *buffer;

@end

@implementation MADReportSectionEnumerator

- (void)dealloc {
    [_buffer removeAllObjects];
}

- (instancetype)init {
    return [self initWithQuery:nil];
}

- (instancetype)initWithQuery:(RptqQuery *)query {
    if (self = [super init]) {
        _query = query;
    }
    return self;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])stackbuf
                                    count:(NSUInteger)stackbufLength {
    static const NSInteger MADIndexMutationPointer = 0;
    static const NSInteger MADIndexGroupCounter    = 1;
    static const NSInteger MADIndexSectionCount    = 2;
    static const NSInteger MADIndexGroupCount      = 3;
    
    NSUInteger count = 0;
    
    RptqQuery *query = _query;
    
    unsigned long countOfItemsAlreadyEnumerated = state->state;
    if(countOfItemsAlreadyEnumerated == 0) {
        state->mutationsPtr = &state->extra[MADIndexMutationPointer];
        state->extra[MADIndexSectionCount] = query ? [query sectionCount] : 0;
        state->extra[MADIndexGroupCounter] = 0;
        state->extra[MADIndexGroupCount]   = query ?  query.hasQueryGroups.count : 0;

        id buffer = [[NSMutableArray alloc] initWithCapacity: MIN(stackbufLength,
                                                                  state->extra[MADIndexSectionCount])];
        self.buffer = buffer;
    }
    
    if(countOfItemsAlreadyEnumerated < state->extra[MADIndexSectionCount]) {
        RptqDocument *document = query.inDatabase.ownedByQueryAsStaticResource;
        
        state->itemsPtr = stackbuf;
        id reportSectionSchema;
        while((countOfItemsAlreadyEnumerated < state->extra[MADIndexSectionCount]) && (count < stackbufLength)) {
            reportSectionSchema = [document documentSectionForSelectedIndex: countOfItemsAlreadyEnumerated
                                                         withNumberOfGroups: state->extra[MADIndexGroupCount]];
            id reportSection = [[MADReportSection alloc] initWithReportSection:reportSectionSchema];
            [_buffer addObject:reportSection];
            stackbuf[count] = reportSection;
            countOfItemsAlreadyEnumerated++;
            count++;
        }
    } else {
        count = 0;
    }
    state->state = countOfItemsAlreadyEnumerated;
    return count;
}

@end
