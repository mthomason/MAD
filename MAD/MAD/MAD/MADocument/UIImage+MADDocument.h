//
//  UIImage+MADDocument.h
//  MAD
//
//  Created by Michael Thomason on 6/4/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIImage.h>

@class MADocument;
@class MTReportFormatter;
@class MTDataTableFast;

@interface UIImage (MADDocument)

    + (instancetype)newImageThumbnailWithDocument:(MADocument *)document;

    + (instancetype)newImageThumbnailWithReportFormatter:(MTReportFormatter *)reportFormatter
                                            andDataTable:(MTDataTableFast *)dataTable;

@end
