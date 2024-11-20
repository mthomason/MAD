//
//  MADReportSectionsEnumerator.h
//  MAD
//
//  Created by Michael Thomason on 6/25/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADReportSectionsEnumerator_h
#define MAD_MADReportSectionsEnumerator_h

#import <Foundation/NSEnumerator.h>

@class MADReportSection, NSArray, RptqDocument, RptqQuery, NSManagedObjectContext;

static inline BOOL validateSelectedIndexWithGroupCount(NSUInteger selectedIndex, NSUInteger numberOfGroups);
static inline BOOL validateSelectedIndexWithGroupCount(NSUInteger selectedIndex, NSUInteger numberOfGroups) {
    return selectedIndex < (numberOfGroups * 2) + 5;
}

static inline NSUInteger queryGroupIndexForSelectedIndexOfTypeHeader(NSUInteger selectedIndex);
static inline NSUInteger queryGroupIndexForSelectedIndexOfTypeHeader(NSUInteger selectedIndex) {
    return selectedIndex - 2;
}

static inline NSUInteger queryGroupIndexForSelectedIndexOfTypeFooter(NSUInteger selectedIndex, NSUInteger numberOfGroups);
static inline NSUInteger queryGroupIndexForSelectedIndexOfTypeFooter(NSUInteger selectedIndex, NSUInteger numberOfGroups) {
    return ((2 + numberOfGroups) - (selectedIndex - (2 + numberOfGroups))) - 2;
}

#endif
