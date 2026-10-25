//
//  MADReportSectionEnumerator.h
//  MAD
//
//  Created by Michael Thomason on 6/26/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADReportSectionEnumerator_h
#define MAD_MADReportSectionEnumerator_h

#import <Foundation/NSEnumerator.h>

@class RptqQuery;

@interface MADReportSectionEnumerator : NSObject <NSFastEnumeration>

@property (nonatomic, readonly, strong) RptqQuery *query;

- (instancetype)initWithQuery:(RptqQuery *)query NS_DESIGNATED_INITIALIZER;

@end

#endif
