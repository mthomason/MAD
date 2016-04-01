//
//  MTReportFormatterState.h
//  MAD
//
//  Created by Michael Thomason on 2/22/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTReportFormatterState_h
#define MAD_MTReportFormatterState_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGBase.h>

@class RptqDocument;

@interface MTReportFormatterState : NSObject

    @property (nonatomic, strong) NSArray *sortDescriptors;
    @property (nonatomic, strong) RptqDocument *document;   //Valid for one run of the state machine.

    @property (nonatomic, strong) NSNumber *detailRowId;
    @property (nonatomic, strong) NSNumber *detailRowIdLast;

    @property (nonatomic, assign) NSUInteger groupCounter;
    @property (nonatomic, assign) NSUInteger pageCounter;
    @property (nonatomic, assign) NSUInteger rowCounter;

    @property (nonatomic, assign) CGFloat counterHeightUsedCurrentPage;

@end

#endif
