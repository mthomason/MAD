//
//  MTPrintPageRendererReport.h
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTPrintPageRendererReport_h
#define Reports_MTPrintPageRendererReport_h

#import <UIKit/UIPrintPageRenderer.h>

@class UIImage;
@class MADReportTextRepresentation;
@class MTReportFormatter;
@class MTDataTableFast;
@class MADocument;

@interface MTReportViewerPrintPageRenderer : UIPrintPageRenderer

    - (instancetype)initWithReportFormatter:(MTReportFormatter *)reportFormatter
                                  dataTable:(MTDataTableFast *)dataTable;

    + (instancetype)newReportViewerPrintPageRenderer:(MADocument *)document;

    @property (nonatomic, strong, readonly) MADReportTextRepresentation *textRepresentation;

    - (void)drawPageAtIndex:(NSUInteger)index inRect:(CGRect)pageRect
        withTransparentBackground:(BOOL)transparentBackground;


@end

#endif
