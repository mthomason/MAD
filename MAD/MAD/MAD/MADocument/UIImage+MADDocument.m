//
//  UIImage+MADDocument.m
//  MAD
//
//  Created by Michael Thomason on 6/4/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "UIImage+MADDocument.h"
#import "MADocument.h"
#import "MTReportViewerPrintPageRenderer.h"
#import "MTReportFormatter.h"
#import "MTDataTableFast.h"
#import "MTPaper.h"
#import <MADCocoaExtensions/CGGeometry+Extras.h>

static inline CGRect imageSizeForPaperSize(CGSize paperSize);
static inline CGRect imageSizeForPaperSize(CGSize paperSize) {
    return MADRectOfSize(CGSizeMake((MADFloat_1024 * paperSize.width) / MADFloat_1024,
                                    (MADFloat_1024 * paperSize.height) / MADFloat_1024));
}

@implementation UIImage (MADDocument)

+ (instancetype)newImageThumbnailWithDocument:(MADocument *)document {
    return [self newImageThumbnailWithReportFormatter:document.reportFormatter
                                         andDataTable:document.mainDataTable];
}

+ (instancetype)newImageThumbnailWithReportFormatter:(MTReportFormatter *)reportFormatter
                                        andDataTable:(MTDataTableFast *)dataTable {
    
    MTReportViewerPrintPageRenderer *printPageRender =
    [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: reportFormatter
                                                           dataTable: dataTable];
    
    UIImage *thumbnail;
    thumbnail = [printPageRender newThumbnailWithRect: imageSizeForPaperSize([MTPaper sizeLetter])
                                                 size: MADFloat_1024
                                           edgeEffect: NO
                                           zoomEffect: NO
                                         squareEffect: YES
                                           cornerSize: 0.0000f
                                                scale: 1.0000f];
    return thumbnail;
}

@end
