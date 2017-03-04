//
//  MADReportSectionsEnumerator.h
//  MAD
//
//  Created by Michael Thomason on 6/25/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADReportSectionsEnumerator_h
#define MAD_MADReportSectionsEnumerator_h

#import <Foundation/NSEnumerator.h>

@class MADReportSection, NSArray, RptqDocument, RptqQuery;

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


@interface MADReportSectionsEnumerator : NSObject
    <NSFastEnumeration>

    - (instancetype)initWithDocument:(RptqDocument *)document NS_DESIGNATED_INITIALIZER;

    @property (nonatomic, readonly, strong) MADReportSection *reportHeader;
    @property (nonatomic, readonly, strong) MADReportSection *pageHeader;
    @property (nonatomic, readonly, strong) NSArray <MADReportSection *> *groupHeaders;
    @property (nonatomic, readonly, strong) MADReportSection *detail;
    @property (nonatomic, readonly, strong) NSArray <MADReportSection *> *groupFooters;
    @property (nonatomic, readonly, strong) MADReportSection *pageFooter;
    @property (nonatomic, readonly, strong) MADReportSection *reportFooter;

    - (NSUInteger)count;
    
@end

#endif
