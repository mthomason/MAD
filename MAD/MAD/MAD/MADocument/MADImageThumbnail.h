//
//  UIImage+MADDocument.h
//  MAD
//
//  Created by Michael Thomason on 6/4/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_UIImage__MADDocument_h
#define Reports_UIImage__MADDocument_h

#import <UIKit/UIImage.h>

@class MADocument, MADPrintPageRenderer;

@interface MADImageThumbnail : UIImage

    + (instancetype)newImageThumbnailWithDocument:(MADocument *)document;
    + (instancetype)newImageThumbnailWithRenderer:(MADPrintPageRenderer *)printPageRenderer;
    + (instancetype)newImageThumbnailWithRect: (CGRect)rect
                                         size: (CGFloat)size
                                   edgeEffect: (BOOL)edgeEffect
                                   zoomEffect: (BOOL)zoomEffect
                                 squareEffect: (BOOL)squareEffect
                                   cornerSize: (CGFloat)cornerSize
                                        scale: (CGFloat)scale
                         andPrintPageRenderer: (MADPrintPageRenderer *)printPageRenderer;
@end

#endif
