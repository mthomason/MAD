//
//  UIImage+MADDocument.h
//  MAD
//
//  Created by Michael Thomason on 6/4/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UIImage__MADDocument_h
#define Reports_UIImage__MADDocument_h

#import <UIKit/UIImage.h>

@class MADocument;
@class MADReportFormatter;
@class MTDataTableFast;

@interface MADImageThumbnail : UIImage

    + (instancetype)newImageThumbnailWithDocument:(MADocument *)document;

@end

#endif
