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
#import <MADCocoaExtensions/MTMath.h>
#import <UIKit/UIGraphics.h>
#import <UIKit/UITraitCollection.h>

static inline CGRect imageSizeForPaperSize(CGSize paperSize);
static inline CGRect imageSizeForPaperSize(CGSize paperSize) {
    return MADRectOfSize(CGSizeMake((MADFloat_1024 * paperSize.width) / MADFloat_1024,
                                    (MADFloat_1024 * paperSize.height) / MADFloat_1024));
}

static inline CGFloat cornerRadiusForHorizontalSizeClass(UIUserInterfaceSizeClass sc);
static inline CGFloat cornerRadiusForHorizontalSizeClass(UIUserInterfaceSizeClass sc) {
    return sc == UIUserInterfaceSizeClassRegular ? 10.0000f : 5.0000f;
}

@implementation UIImage (MADDocument)

+ (instancetype)newImageThumbnailWithDocument:(MADocument *)document {
    return [self newImageThumbnailWithReportFormatter:document.reportFormatter
                                         andDataTable:document.mainDataTable];
}

+ (instancetype)newImageThumbnailWithReportFormatter:(MTReportFormatter *)reportFormatter
                                        andDataTable:(MTDataTableFast *)dataTable {
    
    MTReportViewerPrintPageRenderer *printPageRenderer =
    [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: reportFormatter
                                                           dataTable: dataTable];
    
    UIImage *thumbnail;
    
    
    thumbnail = [self newImageThumbnailWithRect: imageSizeForPaperSize([MTPaper sizeLetter])
                                           size: MADFloat_1024
                                     edgeEffect: NO
                                     zoomEffect: NO
                                   squareEffect: YES
                                     cornerSize: 0.0000f
                                          scale: 1.0000f
                          andPrintPageRenderer: printPageRenderer];
    return thumbnail;
}

+ (instancetype)newImageThumbnailWithTraits:(UITraitCollection *)traits
                       andPrintPageRenderer:(MTReportViewerPrintPageRenderer *)printPageRenderer {
    return [self newImageThumbnailWithRect: [MTPaper rectLetter]
                                      size: MADFloat_1024
                                edgeEffect: YES
                                zoomEffect: YES
                              squareEffect: NO
                                cornerSize: cornerRadiusForHorizontalSizeClass(traits.horizontalSizeClass)
                                     scale: traits.displayScale
                      andPrintPageRenderer: printPageRenderer];
}

+ (instancetype)newImageThumbnailWithRect: (CGRect)rect
                                     size: (CGFloat)size
                               edgeEffect: (BOOL)edgeEffect
                               zoomEffect: (BOOL)zoomEffect
                             squareEffect: (BOOL)squareEffect
                               cornerSize: (CGFloat)cornerSize
                                    scale: (CGFloat)scale
                    andPrintPageRenderer: (MTReportViewerPrintPageRenderer *)printPageRenderer {
    size = size * scale;
    cornerSize = cornerSize * scale;
    CGFloat imageSizeWidth = (size * rect.size.width) / rect.size.height;
    CGRect zoomRect = CGRectMake(CGPointZero.x, CGPointZero.y, imageSizeWidth, size);
    CGRect pathRect = CGRectMake(zoomRect.origin.x, zoomRect.origin.y,
                                 zoomRect.size.width/scale, zoomRect.size.height/scale);
    CGFloat startPointY = pathRect.origin.y + pathRect.size.height;
    CGPoint startPoint = CGPointMake(pathRect.origin.x, startPointY);
    CGPoint topRightPoint = CGPointMake(pathRect.origin.x + pathRect.size.width, pathRect.origin.y);
    CGPoint bottomRightPoint = CGPointMake(pathRect.origin.x + pathRect.size.width, startPointY);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0000f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (zoomEffect) {
        CGMutablePathRef cornerPath = CGPathCreateMutable();
        CGPathMoveToPoint(cornerPath, NULL, startPoint.x, startPoint.y);
        CGPathAddLineToPoint(cornerPath, NULL, pathRect.origin.x, pathRect.origin.y);
        CGPathAddLineToPoint(cornerPath, NULL, topRightPoint.x, topRightPoint.y);
        CGPathAddLineToPoint(cornerPath, NULL, bottomRightPoint.x, bottomRightPoint.y - cornerSize);
        CGPathAddLineToPoint(cornerPath, NULL, bottomRightPoint.x - cornerSize, bottomRightPoint.y);
        CGPathAddLineToPoint(cornerPath, NULL, startPoint.x, startPoint.y);
        CGContextAddPath(context, cornerPath);
        CGContextClosePath (context);
        CGContextClip(context);
        CGPathRelease(cornerPath);
    }
    
    if (edgeEffect) {
        
        CGMutablePathRef zigPath = CGPathCreateMutable();
        CGPathMoveToPoint(zigPath, NULL, startPoint.x, startPoint.y);
        CGPathAddLineToPoint(zigPath, NULL, pathRect.origin.x, pathRect.origin.y);
        CGPathAddLineToPoint(zigPath, NULL, topRightPoint.x, topRightPoint.y);
        
        //zig
        CGFloat zigDivisor = 4.0000f;
        const unsigned int topRandNumber = 4;
        
        CGFloat numberOfZigs = pathRect.size.height / zigDivisor;
        for (NSInteger zigCounter = 0; zigCounter <= numberOfZigs; zigCounter++) {
            NSUInteger zigNumber = madRandomNumberBetween(0, topRandNumber);
            CGFloat zigReal = zigNumber / scale;
            CGFloat zigDistance = (CGFloat)pow(zigNumber, 1.0001) + zigReal;
            CGFloat zigX = topRightPoint.x - zigDistance;
            CGFloat zigY = topRightPoint.y + (zigCounter * zigDivisor);
            CGPoint zigPoint = CGPointMake(zigX, zigY);
            CGPathAddLineToPoint(zigPath, NULL, zigPoint.x, zigPoint.y);
        }
        CGPathAddLineToPoint(zigPath, NULL, startPoint.x, startPoint.y);
        CGContextAddPath(context, zigPath);
        CGContextClip(context);
        CGPathRelease(zigPath);
        
        
        CGMutablePathRef zagPath = CGPathCreateMutable();
        CGPathMoveToPoint(zagPath, NULL, startPoint.x, startPoint.y);
        CGPathAddLineToPoint(zagPath, NULL, pathRect.origin.x, pathRect.origin.y);
        CGPathAddLineToPoint(zagPath, NULL, topRightPoint.x, topRightPoint.y);
        CGPathAddLineToPoint(zagPath, NULL, bottomRightPoint.x, bottomRightPoint.y);
        
        //zag
        CGFloat zagDivisor = 4.0000f;
        CGFloat numberOfZags = pathRect.size.height / zagDivisor;
        for (NSInteger zagCounter = 0; zagCounter <= numberOfZags; zagCounter++) {
            
            NSUInteger zagNumber = madRandomNumberBetween(0, topRandNumber);
            CGFloat zagReal = zagNumber / scale;
            CGFloat zagX = bottomRightPoint.x - (zagCounter * zagDivisor);
            CGFloat zagDistance = (CGFloat)pow(zagNumber, 1.0001) + zagReal;
            CGFloat zagY = bottomRightPoint.y - zagDistance;
            CGPoint zagPoint = CGPointMake(zagX, zagY);
            CGPathAddLineToPoint(zagPath, NULL, zagPoint.x, zagPoint.y);
        }
        CGPathAddLineToPoint(zagPath, NULL, startPoint.x, startPoint.y);
        CGContextAddPath(context, zagPath);
        CGContextClip(context);
        CGPathRelease(zagPath);
    }
    
    
    CGContextSaveGState(context);
    
    [printPageRenderer drawPageAtIndex:0 inRect:rect withTransparentBackground:YES];
    
    CGContextRestoreGState(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *croppedImage;
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, zoomEffect ? zoomRect : rect);
    croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    UIGraphicsEndImageContext();
    
    if (squareEffect) {
        croppedImage = [self newImageMadeSquare:croppedImage];
    }
    
    return croppedImage;
    
}

+ (instancetype)newImageMadeSquare:(UIImage *)source NS_RETURNS_NOT_RETAINED {
    CGSize size = CGSizeMake(MAX(source.size.width, source.size.height),
                             MAX(source.size.width, source.size.height));
    UIGraphicsBeginImageContext(size);
    CGRect rect = CGRectMake(CGPointZero.x + ((size.width - source.size.width) / 2.0000f),
                             CGPointZero.x + ((size.height - source.size.height) / 2.0000f),
                             source.size.width, source.size.height);
    [source drawInRect:rect blendMode:kCGBlendModeNormal alpha:1.0000f];
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIColor *clearColor = [UIColor clearColor];
    CGContextSetStrokeColorWithColor(context, clearColor.CGColor);
    CGContextStrokeRectWithWidth(context, rect, 1.0000f);
    id result =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

@end
