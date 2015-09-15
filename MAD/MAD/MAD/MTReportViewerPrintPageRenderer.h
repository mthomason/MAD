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
#import <MADCocoaExtensions/MADCocoaExtensions.h>

@class MTReportFormatter, MTDataTable;

@interface MTReportViewerPrintPageRenderer : UIPrintPageRenderer

- (instancetype)initWithReportFormatter:(MTReportFormatter *)reportFormatter dataTable:(MTDataTable *)dataTable;
- (UIImage *)thumbnailWithTraits:(UITraitCollection *)traits;
- (UIImage *)thumbnailWithRect:(CGRect)rect
                          size:(CGFloat)size
                    edgeEffect:(BOOL)edgeEffect
                    zoomEffect:(BOOL)zoomEffect
                  squareEffect:(BOOL)squareEffect
                    cornerSize:(CGFloat)cornerSize
                         scale:(CGFloat)scale;

@end

#endif
