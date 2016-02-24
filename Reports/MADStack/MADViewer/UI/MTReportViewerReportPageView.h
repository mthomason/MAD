//
//  MTViewPrintPageRenderReport.h
//  Reports
//
//  Created by Michael Thomason on 2/8/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportViewerReportPageView_h
#define Reports_MTReportViewerReportPageView_h

#import <UIKit/UIKit.h>
#import <MAD/MTReportViewerPrintPageRenderer.h>
#import "MTPrintingProtocol.h"

@class MTReportViewerPrintPageRenderer;

@protocol MADReportPageViewProtocol <NSObject>

    @required
    - (NSUInteger)pageNumber;
    - (NSDate * _Nullable)lastCacheDate;
    - (MTReportViewerPrintPageRenderer * _Nullable)printPageRender;

    @optional
    - (NSUInteger)numberOfPages;

@end

@interface MADReportPageView : UIView

    @property (nonatomic, weak) id <MADReportPageViewProtocol> delegatePage;
    @property (nonatomic, assign) bool drawBlankPage;

@end

#endif
