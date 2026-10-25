//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADReportPageBuilder.h
//  MAD
//
//  The report's page walk, on its own: given a formatted document it builds each
//  page's structure -- the sections in draw order, their rows, and each line's
//  element, frame and resolved text -- and draws it only when the caller hands over a
//  drawing block.  Nothing here is UIKit: MADPrintPageRenderer supplies the block and
//  keeps the UIPrintPageRenderer around it, while a format that wants the report's
//  structure without drawing (json-report, html) reads the same walk with no block at
//  all.  That is what makes the two agree (docs/project/MAD_LINUX.md §9 Phase E).
//
//  It was MADPrintPageRenderer's own -buildPageAtIndex:context:inPageRect: and
//  -buildSection:..., moved; the sequence -- begin a read transaction for the page,
//  resolve every element through MADDocumentObjectDataReference, build one
//  MADReportLineRepresentation per element, commit -- is unchanged.
//

#ifndef MAD_MADReportPageBuilder_h
#define MAD_MADReportPageBuilder_h

#import <Foundation/Foundation.h>

#import <CoreGraphics/CGGeometry.h>

#import <MAD/MADDocumentObjectType.h>
#import <MAD/MADPrintPageRendererDataSource.h>

@class MADPrintPageElement, MADReportPageRepresentation;
@protocol MADDocumentObjectDataReferenceProtocol, MADDocumentRenderProtocol;

NS_ASSUME_NONNULL_BEGIN

/// Draws one element of the page into the caller's own context.  The walk calls it in
/// draw order, with the frame the element's definition places it at.
typedef void (^MADReportPageElementDrawBlock)(__kindof MADPrintPageElement *element, CGRect frame);

@interface MADReportPageBuilder : NSObject

/// The page every render-side format lays out on: US Letter, and the 1pt trim the
/// CLI's PDF export has always drawn inside.  One definition, so the PDF, json-report
/// and the HTML formats agree about where a page ends and an element sits.
+ (CGRect)pageBounds;
+ (CGRect)pageTrimBox;

/// The sequence every render-side format runs before it reads a page: ready the rows,
/// size the formatter to the page and the printable rect, lay the report out.  It is
/// MADCLIDocument's PDF preparation, in one place (docs/project/MAD_LINUX.md §9 Phase E).
+ (void)prepareDocumentForRender:(id <MADDocumentRenderProtocol>)document;

/// A builder over a document, prepared as above.
+ (instancetype)builderForDocument:(id <MADDocumentRenderProtocol>)document;

- (instancetype)initWithDataSource:(NSObject <MADPrintPageRendererDataSourceProtocol> *)dataSource;

/// The object that turns an element's definition into drawing attributes, held weakly.
/// MADPrintPageRenderer is one, with its font-descriptor cache; where nothing is set
/// the walk still resolves every line, which is all a format reads.
@property (nonatomic, weak, nullable) id <MADDocumentObjectDataReferenceProtocol> styler;

/// Builds the page.  `draw` may be NULL, and then nothing is drawn: the page is the
/// walk's structure alone.  Answers nil when the page is past the end of the report.
- (nullable MADReportPageRepresentation *)buildPageAtIndex:(NSUInteger)pageIndex
												inPageRect:(CGRect)pageRect
													  draw:(nullable MADReportPageElementDrawBlock)draw;

@end

NS_ASSUME_NONNULL_END

#endif
