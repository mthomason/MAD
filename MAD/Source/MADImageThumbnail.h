//
//  UIImage+MADDocument.h
//  MAD
//
//  Created by Michael Thomason on 6/4/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_UIImage__MADDocument_h
#define Reports_UIImage__MADDocument_h

#import <UIKit/UIImage.h>

@class MADocument, MADPrintPageRenderer;

@interface MADImageThumbnail : UIImage
+ (instancetype)newImageThumbnailWithRenderer:(MADPrintPageRenderer *)printPageRenderer;
@end

#endif
