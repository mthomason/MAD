//
//  MTViewControllerReportPage.h
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportViewerReportPageViewController_h
#define Reports_MTReportViewerReportPageViewController_h

#import <UIKit/UIViewController.h>

@protocol MTPrintingProtocol;

@class MADocument;
@class MADPageViewAttributes;

@interface MADReportPageViewController : UIViewController

    + (instancetype)newReportPageViewControllerWithDocument:(MADocument *)document
                                             pageAttributes:(MADPageViewAttributes *)pageAttributes;

    - (instancetype)initWithDocument:(MADocument *)document
                  andPageAttributtes:(MADPageViewAttributes *)pageAttributes;

    @property (nonatomic, weak) id <MTPrintingProtocol> delegate;

    @property (readonly) UIScrollView *documentScroller;
    @property (readonly, nonatomic, weak) UIView *documentView;
    @property (readonly, nonatomic, copy) MADPageViewAttributes *pageViewAttributes;

@end

#endif
