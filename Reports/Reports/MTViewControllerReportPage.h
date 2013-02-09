//
//  MTViewControllerReportPage.h
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTPrintPageRendererReport.h"
#import "MTViewPrintPageRenderReport.h"

@interface MTViewControllerReportPage : UIViewController

@property (nonatomic, retain) RptqDocument *document;
@property (nonatomic, assign, readonly) NSUInteger pageNumber;

- (id)initWithPageData:(MTPrintPageRendererReport *)pageData andPageNumber:(NSUInteger)pageNumber;

@end