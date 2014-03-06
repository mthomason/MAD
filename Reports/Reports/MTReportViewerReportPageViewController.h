//
//  MTViewControllerReportPage.h
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "MTReportViewerReportPageView.h"
#import "UIColor+EverydayApps.h"

@interface MTReportViewerReportPageViewController : UIViewController
    <MTPrintingProtocol>

@property (nonatomic, assign) id <MTPrintingProtocol> delegate;

@property (nonatomic, assign, readonly) NSUInteger pageNumber;
@property (nonatomic, retain) NSDate *lastCacheDate;

- (id)initWithPageNumber:(NSUInteger)pageNumber ofPages:(NSUInteger)numberOfPages;

@end
