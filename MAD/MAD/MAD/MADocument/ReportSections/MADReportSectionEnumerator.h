//
//  MADReportSectionEnumerator.h
//  MAD
//
//  Created by Michael Thomason on 6/26/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADReportSectionEnumerator_h
#define MAD_MADReportSectionEnumerator_h

#import <Foundation/NSEnumerator.h>

@class RptqQuery;

@interface MADReportSectionEnumerator : NSObject
    <NSFastEnumeration>

    - (instancetype)initWithQuery:(RptqQuery *)query NS_DESIGNATED_INITIALIZER;

    @property (nonatomic, readonly, weak) RptqQuery *query;

@end

#endif
