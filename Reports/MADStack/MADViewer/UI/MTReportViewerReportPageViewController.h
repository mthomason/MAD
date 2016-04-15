//
//  MTViewControllerReportPage.h
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportViewerReportPageViewController_h
#define Reports_MTReportViewerReportPageViewController_h

#import <MAD/MADocument.h>
#import <MAD/MTPaper.h>
#import "MTPrintingProtocol.h"

@class MADocument, MADPageViewAttributes;

@interface MADReportPageViewController : UIViewController

    @property (nonatomic, weak) id <MTPrintingProtocol> delegate;

    @property (readonly) UIScrollView *documentScroller;
    @property (nonatomic, weak, readonly) UIView *documentView;
    @property (nonatomic, copy, readonly) MADPageViewAttributes *pageViewAttributes;

    + (instancetype)newReportPageViewControllerWithDocument:(MADocument *)document
                                             pageAttributes:(MADPageViewAttributes *)pageAttributes frame:(CGRect)frame
                                                andDelegate:(id <MTPrintingProtocol>)delegate;

    - (instancetype)initWithDocument:(MADocument *)document andPageAttributtes:(MADPageViewAttributes *)pageAttributes;

@end

#endif
