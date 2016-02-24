//
//  MTViewControllerReportPage.h
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportViewerReportPageViewController_h
#define Reports_MTReportViewerReportPageViewController_h

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <MADDataStructures/MADDataStructures.h>
#import <MAD/MADocument.h>
#import <MAD/MTPaper.h>
#import "MTPrintingProtocol.h"

@class MADocument;
@class MADPageViewAttributes;

@interface MADReportPageViewController : UIViewController

    @property (nonatomic, weak) id <MTPrintingProtocol> delegate;

    @property (nonatomic, weak, readonly) UIView *documentView;
    @property (readonly) UIScrollView *documentScroller;
    @property (nonatomic, strong, readonly) MADPageViewAttributes *pageViewAttributes;

+ (instancetype)PageViewControllerWithDocument:(MADocument *)document
                                pageAttributes:(MADPageViewAttributes *)pageAttributes
                                         frame:(CGRect)frame
                                   andDelegate:(id <MTPrintingProtocol>)delegate;
- (instancetype)initWithDocument:(MADocument *)document andPageAttributtes:(MADPageViewAttributes *)pageAttributes;

@end

#endif
