//
//  MTPrintPageRendererReport.h
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTPrintPageRendererReport_h
#define Reports_MTPrintPageRendererReport_h

#import <UIKit/UIKit.h>
#import "RptqDocument+Extras.h"
#import "RptqDocumentObject+Extras.h"
#import "RptqDocumentObjectLabelDataField+Extras.h"
#import "RptqQueryGroup+Extras.h"
#import "RptqQuery+Extras.h"
#import "CGGeometry+Extras.h"
#import "MTPrintPageRenderReportPageData.h"

@interface MTPrintPageRendererReport : UIPrintPageRenderer <NSCopying>

- (id)initWithDocument:(RptqDocument *)document;
- (id)initWithDocument:(RptqDocument *)document andPrintableAreaSize:(CGSize)printableAreaSize;
- (void)cachePrintPageRenderDataForSize:(CGSize)printableSize;

@end

#endif
