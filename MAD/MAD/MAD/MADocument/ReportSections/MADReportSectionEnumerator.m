//
//  MADReportSectionEnumerator.m
//  MAD
//
//  Created by Michael Thomason on 6/26/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADReportSectionEnumerator.h"
#import "RptqQuery+Extras.h"

const NSInteger MADIndexMutationPointer = 0;
const NSInteger MADIndexGroupCounter    = 1;
const NSInteger MADIndexSectionCount    = 2;
const NSInteger MADIndexGroupCount      = 3;

@interface MADReportSectionEnumerator ()

    @property (nonatomic, readwrite, weak) RptqQuery *query;

@end

@implementation MADReportSectionEnumerator

- (instancetype)initWithQuery:(RptqQuery *)query {
    if (self = [super init]) {
        _query = query;
    }
    return self;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])stackbuf
                                    count:(NSUInteger)stackbufLength {
    NSUInteger count = 0;
    
    RptqQuery *query = _query;
    
    unsigned long countOfItemsAlreadyEnumerated = state->state;
    if(countOfItemsAlreadyEnumerated == 0) {
        state->mutationsPtr = &state->extra[MADIndexMutationPointer];
        state->extra[MADIndexGroupCounter] = 0;
        state->extra[MADIndexSectionCount] = [query sectionCount];
        state->extra[MADIndexGroupCount]    = query.hasQueryGroups.count;
    }
    
    if(countOfItemsAlreadyEnumerated < state->extra[MADIndexSectionCount]) {
        state->itemsPtr = stackbuf;
        while((countOfItemsAlreadyEnumerated < state->extra[MADIndexSectionCount]) && (count < stackbufLength)) {
        
            stackbuf[count] = [query documentSectionForSelectedIndex: countOfItemsAlreadyEnumerated
                                                  withNumberOfGroups: state->extra[MADIndexGroupCount]];
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
