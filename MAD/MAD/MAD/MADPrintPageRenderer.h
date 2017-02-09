//
//  MADPrintPageRendererReport.h
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADPrintPageRendererReport_h
#define Reports_MADPrintPageRendererReport_h

#import <UIKit/UIPrintPageRenderer.h>

@class UIImage, MADReportTextRepresentation, MADReportFormatter, MADDataTableFast, MADocument;

@protocol MADPrintPageRendererDataSourceProtocol;

@interface MADPrintPageRenderer : UIPrintPageRenderer

    - (instancetype)initWithDataSource:(NSObject <MADPrintPageRendererDataSourceProtocol> *)datasource;

    + (instancetype)newReportViewerPrintPageRendererWithDataSource:(NSObject <MADPrintPageRendererDataSourceProtocol> *)datasource;

    @property (nonatomic, strong, readonly) MADReportTextRepresentation *textRepresentation;

    - (void)drawPageAtIndex:(NSUInteger)index inRect:(CGRect)pageRect
        withTransparentBackground:(BOOL)transparentBackground;


@end

#endif
