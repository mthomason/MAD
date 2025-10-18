//
//  MADPrintPageRendererReport.h
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADPrintPageRendererReport_h
#define Reports_MADPrintPageRendererReport_h

#import <UIKit/UIPrintPageRenderer.h>

@class UIImage, MADReportTextRepresentation, MADReportFormatter, MADDataTableFast, MADocument;
@protocol MADPrintPageRendererDataSourceProtocol;

@interface MADPrintPageRenderer : UIPrintPageRenderer

@property (nonatomic, strong, readonly) MADReportTextRepresentation *textRepresentation;

- (instancetype)initWithDataSource:(NSObject <MADPrintPageRendererDataSourceProtocol> *)datasource;
- (void)drawPageAtIndex:(NSUInteger)index inRect:(CGRect)pageRect withTransparentBackground:(BOOL)transparentBackground;

@end

#endif
