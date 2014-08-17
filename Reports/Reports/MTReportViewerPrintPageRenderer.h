//
//  MTPrintPageRendererReport.h
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTPrintPageRendererReport_h
#define Reports_MTPrintPageRendererReport_h

#import <UIKit/UIKit.h>

@class MTReportFormatter, MTDataTable;

@interface MTReportViewerPrintPageRenderer : UIPrintPageRenderer

- (instancetype)initWithReportFormatter:(MTReportFormatter *)reportFormatter dataTable:(MTDataTable *)dataTable;
- (UIImage *)thumbnail;

@end

#endif
