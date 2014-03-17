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

@class MAReportDocument;

@interface MTReportViewerPrintPageRenderer : UIPrintPageRenderer
    <NSCopying>

@property (nonatomic, assign) BOOL didRefresh;

- (id)initWithDocument:(MAReportDocument *)document;
- (id)initWithDocument:(MAReportDocument *)document andPrintableAreaSize:(CGSize)printableAreaSize;
- (void)cachePrintPageRenderDataForSize:(CGSize)printableSize;
- (void)writeToPdf:(NSURL *)filepath;
- (UIImage *)thumbnail;

@end

#endif
