//
//  MADPrintPageRendererReport.h
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADPrintPageRendererReport_h
#define Reports_MADPrintPageRendererReport_h

#include <TargetConditionals.h>
#if defined(__APPLE__) && TARGET_OS_IPHONE
#import <UIKit/UIPrintPageRenderer.h>
typedef UIPrintPageRenderer MADPlatformPrintPageRenderer;
#else
#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>
#import <CoreGraphics/CGContext.h>
typedef NSObject MADPlatformPrintPageRenderer;
#endif

@class MADReportTextRepresentation, MADReportFormatter, MADDataTableFast, MADocument, MADReportPageRepresentation;
@protocol MADPrintPageRendererDataSourceProtocol;

NS_ASSUME_NONNULL_BEGIN

@interface MADPrintPageRenderer : MADPlatformPrintPageRenderer

@property (nonatomic, strong, readonly) MADReportTextRepresentation *textRepresentation;

- (instancetype)initWithDataSource:(NSObject <MADPrintPageRendererDataSourceProtocol> *)datasource;
- (NSInteger)numberOfPages;
- (void)drawPageAtIndex:(NSInteger)index inRect:(CGRect)pageRect;
- (void)drawPageAtIndex:(NSUInteger)index inRect:(CGRect)pageRect withTransparentBackground:(BOOL)transparentBackground;

/// The page's walk, with the drawing optional: a context draws the page into the
/// current UIKit context as -drawPageAtIndex:withContext:inPageRect: always has,
/// while NULL only builds the representation and returns it.  A format that wants the
/// report's structure -- its sections, their elements and each element's resolved
/// text -- without drawing reads it here (docs/project/MAD_LINUX.md §9 Phase E); the page is also
/// recorded in -textRepresentation either way.
- (nullable MADReportPageRepresentation *)buildPageAtIndex:(NSUInteger)pageIndex
												   context:(CGContextRef _Nullable)ctx
												inPageRect:(CGRect)pageRect;

@end

NS_ASSUME_NONNULL_END

#endif
