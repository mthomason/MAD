//
//  MADReportPageView.h
//  Reports
//
//  Created by Michael Thomason on 2/8/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADReportPageView_h
#define Reports_MADReportPageView_h

#import <UIKit/UIView.h>

@class MADPrintPageRenderer;

@protocol MADReportPageViewProtocol <NSObject>

    @required
    - (NSUInteger)pageNumber;
    - (NSDate * _Nullable)lastCacheDate;
    - (MADPrintPageRenderer * _Nullable)printPageRenderer;

    @optional
    - (NSUInteger)numberOfPages;

@end

@interface MADReportPageView : UIView

    @property (nonatomic, weak) id <MADReportPageViewProtocol> _Nullable delegatePage;
    @property (nonatomic, assign) BOOL drawBlankPage;

@end

#endif
