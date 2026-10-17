//
//  MADReportPageBuilder.m
//  MAD
//
//  See MADReportPageBuilder.h: MADPrintPageRenderer's page walk, moved out of the
//  UIKit subclass so the formats that only want the structure can read it too.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADReportPageBuilder.h"

#import "MADocumentSectionType.h"
#import "MADDocumentObjectDataReference.h"
#import "MADPrintPageElement.h"
#import "MADPrintPageElement+Constructor.h"
#import "MADReportFormatter.h"
#import "MADReportLineRepresentation.h"
#import "MADReportPageRepresentation.h"
#import "MADReportSectionRepresentation.h"
#import "MADReportSectionRowsRepresentation.h"
#import "MADSectionRepresentation.h"
#import "MTPaper.h"
#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDocumentElement.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDocumentSectionRows.h"

#import <MADFoundation/madlog.h>

#import <MADSqlite3/MADDataTableFast.h>

#import <CoreFoundation/CFNumber.h>

// The page's four-edge insets; the compat shim answers this off Apple too.
#import <UIKit/UIGeometry.h>

static inline CGRect ElementBounds(CGRect, CGPoint);
static inline CGFloat HeightWithVisibility(CGFloat, BOOL);
static inline CGRect SectionBounds(CGRect, CGFloat, BOOL, MADDocumentSectionType, NSUInteger, NSUInteger, CGFloat);

static inline CGRect ElementBounds(CGRect frame, CGPoint bounds) { return CGRectMake(frame.origin.x + bounds.x, frame.origin.y + bounds.y, frame.size.width, frame.size.height); }

static inline CGFloat HeightWithVisibility(CGFloat height, BOOL visibility) { return visibility ? height : CGSizeZero.height; }

// Where a section sits on the page: the page's own box for most of them, and pinned
// to the bottom for the two footers, the way the walk has always placed them.
static inline CGRect SectionBounds(CGRect pageRect, CGFloat sectionHeight,
								   BOOL visility, MADDocumentSectionType sectionType,
								   NSUInteger numberOfPages, NSUInteger pageIndex,
								   CGFloat originY) {

	switch (sectionType) {

		case MADDocumentSectionTypePageFooter:
			originY = pageIndex == numberOfPages - 1 ?  // last page?
				pageRect.origin.y + pageRect.size.height - HeightWithVisibility(sectionHeight, visility) - sectionHeight :
				pageRect.origin.y + pageRect.size.height - HeightWithVisibility(sectionHeight, visility);
			break;

		case MADDocumentSectionTypeReportFooter:
			originY = pageRect.origin.y + pageRect.size.height - sectionHeight;
			break;

		default:
			break;
	}
	return CGRectMake(pageRect.origin.x, originY, pageRect.size.width, HeightWithVisibility(sectionHeight, visility));
}

// The walk's own data-reference delegate: every element it builds asks it for drawing
// attributes, and it answers with the styler's or with none.  Adopted here rather than
// in the header, which is public and MADDocumentObjectDataReference.h is not.
@interface MADReportPageBuilder () <MADDocumentObjectDataReferenceProtocol>
@end

@implementation MADReportPageBuilder {
	__weak NSObject <MADPrintPageRendererDataSourceProtocol> *_dataSource;
}

#pragma mark - The render side's geometry and preparation

+ (CGRect)pageBounds {
	return [[MTPaper alloc] initWithType: MTPaperTypeLetter].bounds;
}

+ (CGRect)pageTrimBox {
	return UIEdgeInsetsInsetRect([self pageBounds], UIEdgeInsetsMake(1.0, 1.0, 1.0, 1.0));
}

+ (void)prepareDocumentForRender:(id <MADDocumentRenderProtocol>)document {
	// The reload the viewer runs after a refresh, which the CLI has no view controller
	// to run for it: sort the rows, then lay the report out.  MADPrintPageRenderer
	// draws from the document's own formatter -- not from a second one built alongside
	// it -- so this is the formatter that has to be formatted.
	[document prepareForQuery];

	MADReportFormatter *reportFormatter = document.reportFormatter;
	reportFormatter.overrideIdentifier = @"madpreview";
	reportFormatter.didRefresh = YES;
	reportFormatter.layoutSize = [self pageBounds].size;
	[reportFormatter setMarginUsingPrintableRect: [self pageTrimBox]];
	[document format];
}

+ (instancetype)builderForDocument:(id <MADDocumentRenderProtocol>)document {
	[self prepareDocumentForRender: document];
	return [[self alloc] initWithDataSource: document];
}

- (instancetype)initWithDataSource:(NSObject <MADPrintPageRendererDataSourceProtocol> *)dataSource {
	if (self = [super init]) {
		_dataSource = dataSource;
	}
	return self;
}

#pragma mark - MADDocumentObjectDataReferenceProtocol

// Every element resolves its definition through the walk, and asks for its drawing
// attributes when there is something to draw with.  Off Apple nothing draws, so a
// walk with no styler answers with no attributes rather than with nil.
- (NSDictionary <NSString *, id> *)fontAttributes:(MADDocumentObjectDataReference *)dataRef {
	id <MADDocumentObjectDataReferenceProtocol> styler = self.styler;
	if (styler != nil) {
		return [styler fontAttributes: dataRef];
	}
	return @{};
}

#pragma mark - The walk

- (MADReportPageRepresentation *)buildPageAtIndex:(NSUInteger)pageIndex
									   inPageRect:(CGRect)pageRect
											 draw:(MADReportPageElementDrawBlock)draw {

	NSObject <MADPrintPageRendererDataSourceProtocol> *datasource = _dataSource;
	MADReportFormatter *reportFormatter = datasource.reportFormatter;
	if (pageIndex >= reportFormatter.numberOfPages) {
		return nil;
	}

	// One read transaction for the whole page: every cell read would otherwise pay
	// autocommit's journal begin/commit on its own.  See BUGS.md "Page draws run one
	// SQLite transaction per cell".  Only the page-bound check above can return
	// early, so the pair below stays balanced.
	[datasource.dataTable beginReadTransaction];

	CGFloat originY = pageRect.origin.y;
	NSUInteger offsetElement = 0;

	RptqDocument *document = (reportFormatter.layout).activeDocumentModel;
	NSEnumerator *layoutEnumerator = [reportFormatter layoutEnumerator:pageIndex];
	MADReportPageRepresentation *pageRepresentation = [[MADReportPageRepresentation alloc] initWithNumberOfSections:0];

	for (MADSectionRepresentation *pageSection in layoutEnumerator) {
		RptqDocumentSection *documentSection = [document documentSectionForType: pageSection.sectionType
																	   andLevel: pageSection.groupLevel];

		NSNumber *sectionIdentifier = @(documentSection.identifier);
		CGRect rect = SectionBounds(pageRect, HeightWithVisibility([reportFormatter heightSection:sectionIdentifier], documentSection.visibility), documentSection.visibility, pageSection.sectionType, reportFormatter.numberOfPages, pageIndex, originY);

		MADReportSectionRepresentation *sectionRepresentation = [self buildSection: documentSection
																			inRect: rect
																		  pageRect: pageRect
																	   pageSection: pageSection
																		  document: document
																		 pageIndex: pageIndex
																		   ofPages: reportFormatter.numberOfPages
																			offset: originY
																	 offsetElement: offsetElement
																			  draw: draw];

		[pageRepresentation addSection:sectionRepresentation];

		originY += rect.size.height;
	}

	[datasource.dataTable commitReadTransaction];

	return pageRepresentation;
}

- (MADReportSectionRepresentation *)buildSection: (RptqDocumentSection *)documentSection
										  inRect: (CGRect)rect
										pageRect: (CGRect)pageRect
									 pageSection: (MADSectionRepresentation *)pageSection
										document: (RptqDocument *)document
									   pageIndex: (NSUInteger)pageIndex
										 ofPages: (NSUInteger)numberOfPages
										  offset: (CGFloat)originY
								   offsetElement: (NSUInteger)offsetElement
											draw: (MADReportPageElementDrawBlock)draw {

	MADReportSectionRepresentation * _Nonnull sectionRepresentation = [[MADReportSectionRepresentation alloc] initWithNumberOfRows:1];
	sectionRepresentation.type = pageSection.sectionType;
	sectionRepresentation.groupLevel = pageSection.groupLevel;
	sectionRepresentation.elementOffset = offsetElement;
	sectionRepresentation.visibility = documentSection.visibility;

	if (sectionRepresentation.visibility) {
		NSObject <MADPrintPageRendererDataSourceProtocol> *datasource = _dataSource;
		NSEnumerator <RptqDocumentSectionRows *> *rowsEnumerator = documentSection.hasRows.objectEnumerator;

		for (RptqDocumentSectionRows *row in rowsEnumerator) {
			NSEnumerator *documentObjectEnumerator = row.hasObjects.objectEnumerator;
			MADReportSectionRowsRepresentation * _Nonnull rowRepresentation = [[MADReportSectionRowsRepresentation alloc] initWithNumberOfSectionRowElements:0];

			for (__kindof RptqDocumentElement *item in documentObjectEnumerator) {

				MADDocumentObjectDataReference *dataReference = [MADDocumentObjectDataReference newDocumentObjectDataReference: datasource
																													  delegate: self
																														  page: pageIndex
																														  item: item
																														itemID: pageSection.detailRowId];

				__kindof MADPrintPageElement *drawingObject = [MADPrintPageElement newDocumentObject:dataReference];

				// Where the element sits on the page: its own frame, offset by the
				// section it lives in.  The line carries this frame, so a format that
				// reads the walk places the line where the drawing would.
				CGRect frame = ElementBounds(item.frame, rect.origin);

				// The element is built either way -- its text is resolved in its
				// initializer -- and drawn only when there is a page to draw on.
				if (draw != NULL) {
					draw(drawingObject, frame);
				}

				MADReportLineRepresentation * _Nonnull line = [[MADReportLineRepresentation alloc] initWithObject: drawingObject
																											 type: item.documentObjectType
																											frame: frame];
				// The element's styling is read here, while the page's read transaction
				// is open, so a format that is not Core Graphics can spell the line the
				// way MADElementStylizedText would have drawn it.
				line.style = [MADReportLineStyle styleForElement: item];
				line.elementOffset = offsetElement;
				offsetElement++;

				[rowRepresentation addLine:line];
			}
			NSError *error = nil;
			bool addedRow = [sectionRepresentation addRow:rowRepresentation error:&error];
			if (!addedRow && error != nil) {
				os_log_error(GetMadLog(), "%s", error.localizedDescription.UTF8String);
			}
		}
	}
	return sectionRepresentation;
}

@end
