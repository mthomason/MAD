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

@protocol MADPrintPageRendererDataSourceProtocol;

@interface MTReportViewerPrintPageRenderer : UIPrintPageRenderer

    - (instancetype)initWithDataSource:(NSObject <MADPrintPageRendererDataSourceProtocol> *)datasource;

    + (instancetype)newReportViewerPrintPageRendererWithDataSource:(NSObject <MADPrintPageRendererDataSourceProtocol> *)datasource;

    @property (nonatomic, strong, readonly) MADReportTextRepresentation *textRepresentation;

    - (void)drawPageAtIndex:(NSUInteger)index inRect:(CGRect)pageRect
        withTransparentBackground:(BOOL)transparentBackground;


@end

#endif
