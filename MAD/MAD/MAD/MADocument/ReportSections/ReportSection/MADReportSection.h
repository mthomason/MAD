//
//  MADReportSection.h
//  MAD
//
//  Created by Michael Thomason on 6/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADReportSection_h
#define MAD_MADReportSection_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGBase.h>
#import "MADocumentSectionType.h"

@class MADReportRows, MADSectionLayoutManager, NSManagedObjectID, NSManagedObjectContext,
       RptqDocumentSection;

@interface MADReportSection : NSObject

    - (instancetype)initWithReportSection:(RptqDocumentSection *)reportSection;

    @property (nonatomic, readonly, strong)                         RptqDocumentSection *documentSection;
    @property (nonatomic, readonly, strong)                         NSNumber *objectID;

    @property (nonatomic, readonly)                                 NSInteger identifier;

    @property (nonatomic, readonly, strong, getter=hasReportRows)   MADReportRows *reportRows;
    @property (nonatomic, readonly, strong)                         MADSectionLayoutManager *layoutManager;

    @property (nonatomic, readonly, getter=isVisible)               BOOL visible;
    @property (nonatomic, readonly)                                 CGFloat height;
    @property (nonatomic, readonly)                                 MADDocumentSectionType type;

    @property (nonatomic, readonly)                                 NSString *localizedDisplayName;


@end

#endif
