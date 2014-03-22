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

@class MAReportDocument, MTReportFormatter;

@interface MTReportViewerPrintPageRenderer : UIPrintPageRenderer

- (id)initWithReportFormatter:(MTReportFormatter *)reportFormatter;
- (id)initWithReportFormatter:(MTReportFormatter *)reportFormatter andPrintableAreaSize:(CGSize)printableAreaSize;
- (void)writeToPdf:(NSURL *)filepath;
- (UIImage *)thumbnail;

@end

#endif
