//
//  MADReportSections.h
//  MAD
//
//  Created by Michael Thomason on 6/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADReportSections_h
#define MAD_MADReportSections_h

#import <Foundation/NSObject.h>

@class MADReportSection;
@class RptqDocument;
@class RptqQuery;

@protocol MADReportSectionsDelegate;
@protocol MADReportSectionsDelegate <NSObject>

    - (RptqDocument *)documentSchema;
    - (RptqQuery *)mainQuery;

@end

@interface MADReportSections : NSObject

    - (instancetype)initWithDelegate:(id <MADReportSectionsDelegate>) delegate;
    
    @property (nonatomic, readonly, weak) id <MADReportSectionsDelegate> delegate;
    @property (nonatomic, readonly, strong, getter=hasReportSections) NSArray <MADReportSection *> *reportSections;

@end

#endif
