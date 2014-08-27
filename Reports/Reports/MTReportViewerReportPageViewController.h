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
#import "MTReportViewerReportPageView.h"
#import "UIColor+EverydayApps.h"
#import "Constants.h"

@class MADocument;

@interface MTReportViewerReportPageViewController : UIViewController
    <MTPrintingProtocol>

@property (nonatomic, assign) id <MTPrintingProtocol> delegate;

@property (nonatomic, assign, readonly) NSUInteger pageNumber;
@property (nonatomic, strong) NSDate *lastCacheDate;

- (instancetype)initWithDocument:(MADocument *)document PageNumber:(NSUInteger)pageNumber ofPages:(NSUInteger)numberOfPages NS_DESIGNATED_INITIALIZER;

@end

#endif
