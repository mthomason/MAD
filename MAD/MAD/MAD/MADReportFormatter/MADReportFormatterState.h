//
//  MADReportFormatterState.h
//  MAD
//
//  Created by Michael Thomason on 2/22/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADReportFormatterState_h
#define MAD_MADReportFormatterState_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGBase.h>

@protocol MADDataProtocol;

@class RptqDocument;

@interface MADReportFormatterState : NSObject

    - (instancetype)initWithDocument:(RptqDocument *)document
                     andDataDelegate:(id <MADDataProtocol>)dataDelegate;

    - (void)resetWithDocument:(RptqDocument *)document
              andDataDelegate:(id <MADDataProtocol>)dataDelegate;

    @property (nonatomic, strong) NSArray *sortDescriptors;
    @property (nonatomic, strong) RptqDocument *document;   //Valid for one run of the state machine.

    @property (nonatomic, assign) NSUInteger detailRowId;
    @property (nonatomic, assign) NSUInteger detailRowIdLast;

    @property (nonatomic, assign) NSUInteger groupCounter;
    @property (nonatomic, assign) NSUInteger pageCounter;
    @property (nonatomic, assign) NSUInteger rowCounter;

    @property (nonatomic, assign) CGFloat counterHeightUsedCurrentPage;

@end

#endif
