//
//  MADReportSection.h
//  MAD
//
//  Created by Michael Thomason on 6/25/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADReportSection_h
#define MAD_MADReportSection_h

#import <MAD/MADocumentSectionType.h>
#import <Foundation/NSObject.h>
#import <CoreGraphics/CGBase.h>

@class MADReportRows, MADSectionLayoutManager, RptqDocumentSection;

@interface MADReportSection : NSObject

- (instancetype)initWithReportSection:(RptqDocumentSection *)reportSection;

@property (nonatomic, readonly, strong) RptqDocumentSection *documentSection;
@property (nonatomic, readonly, strong) NSNumber *objectID;

@property (nonatomic, readonly) NSInteger identifier;

@property (nonatomic, readonly, strong, getter=hasReportRows) MADReportRows *reportRows;
#if __APPLE__
// The section's layout is the designer's; MADSectionLayoutManager is not in
// the Linux build (MADocument was its only client).
@property (nonatomic, readonly, strong) MADSectionLayoutManager *layoutManager;
#endif

@property (nonatomic, readonly, getter=isVisible) BOOL visible;
@property (nonatomic, readonly) CGFloat height;
@property (nonatomic, readonly) MADDocumentSectionType type;

@property (nonatomic, readonly) NSString *localizedDisplayName;

@end

#endif
