//
//  MADPrintPageRendererReport.m
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADPrintPageRenderer.h"

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDocumentElement.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqDatabase.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField.h"
#import "RptqDatabaseCredentals.h"
#import "RptqDocumentSectionRows.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDocumentElementAggregate+Extras.h"
#import "RptqDocumentElementBarcode+Extras.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqTextStyle.h"
#import "RptqAlignment.h"
#import "RptqDocumentElementLabel.h"
#import "RptqDocumentElementLabelDataField+Extras.h"
#import "RptqDocumentElementImage.h"
#import "MADocument.h"
#import "MADParameters+QueryCacheAggregate.h"
#import "MADElementStylizedText.h"
#import "MADPrintPageRendererDataSource.h"
#import "MADDocumentObjectDataReference.h"
#import "MADPrintPageElement.h"
#import "MADPrintPageElement+Constructor.h"
#import "MADSectionRepresentation.h"
#import "MADReportTextRepresentation.h"
#import "MADReportPageRepresentation.h"
#import "MADReportSectionRepresentation.h"
#import "MADReportSectionRowsRepresentation.h"
#import "MADReportLineRepresentation.h"
#import "MADReportPageBuilder.h"

#import <MADQueryCacheAggregateFunctionParamaters.h>

#import <MADCocoaExtensions/MTMath.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import <MAD/MTPaper.h>
#import <MAD/MADReportFormatter.h>
#import <MADAPI/MADQuery.h>
#import <MADAPI/MADDatabase.h>

#import <MADSqlite3/MADArrayCaching.h>
#import <MADSqlite3/MADDataTableFast.h>

#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseField.h>

#import <UIKit/UIGraphics.h>
#import <UIKit/UIImage.h>
#import <UIKit/NSStringDrawing.h>
#import <UIKit/UIInterface.h>
#import <UIKit/NSParagraphStyle.h>

#import <MADFoundation/madlog.h>

static os_log_t log_print;

@class MTBarcode;

static NSString * const MTCachedSizeHorizontal = @"MTCachedSizeHorizontal";
static NSString * const MTCachedSizeVertical = @"MTCachedSizeVertical";

@interface MADPrintPageRenderer ()
	<MADDocumentObjectDataReferenceProtocol>

	//@property (nonatomic, strong) NSArray <__kindof MADAccessibilityLine *> *accessibilityItems;
	@property (nonatomic, assign) NSUInteger accessibilityCurrentPageIndex;
	@property (nonatomic, assign) CGRect accessibilityCurrentPageRect;
	@property (nonatomic, strong, readwrite) MADReportTextRepresentation *textRepresentation;
	@property (nonatomic, weak) NSObject <MADPrintPageRendererDataSourceProtocol> *datasource;
	@property (readwrite, nonatomic, strong) NSMutableDictionary <NSNumber *, MADElementStylizedText *> *fontDescriptors;
	@property (nonatomic, strong) MADReportPageBuilder *pageBuilder;

@end

@implementation MADPrintPageRenderer {
	BOOL _showWaterMark;
	BOOL _accessibilityCacheNeedsUpdate;
	NSUInteger _accessibilityCurrentPageIndex;
}

+ (void)initialize {
	[super initialize];
	if (self == [MADPrintPageRenderer self]) {
		NSString *c = NSStringFromClass([MADPrintPageRenderer class]);
		log_print = os_log_create("com.mad", c.UTF8String);

		if ([[NSUserDefaults standardUserDefaults] valueForKey:MTCachedSizeHorizontal] == nil) {
			[[NSUserDefaults standardUserDefaults] setObject: NSStringFromCGSize(CGSizeZero) forKey: MTCachedSizeHorizontal];
			[[NSUserDefaults standardUserDefaults] setObject: NSStringFromCGSize(CGSizeZero) forKey: MTCachedSizeVertical];
			[[NSUserDefaults standardUserDefaults] synchronize];
			
		}
	}
}

#pragma mark -
#pragma mark Helpers Drawing

+ (void)drawWhiteCanvas:(CGContextRef)ctx pageRect:(CGRect)pageRect {
	[[UIColor whiteColor] setFill];
	CGPathRef path = CGPathCreateWithRect(pageRect, NULL);
	CGContextAddPath(ctx, path);
	CGContextDrawPath(ctx, kCGPathFill);
	CGPathRelease(path);
}

#pragma mark -
#pragma mark NSObject

- (void)dealloc { }

#pragma mark -
#pragma mark Constructors

- (instancetype)initWithDataSource:(NSObject <MADPrintPageRendererDataSourceProtocol> *)datasource {
	if (self = [super init]) {
		self.datasource = datasource;
		_accessibilityCacheNeedsUpdate = NO;
		
		NSMutableDictionary <NSNumber *, MADElementStylizedText *> *fontDescriptors = [[NSMutableDictionary <NSNumber *, MADElementStylizedText *>alloc] init];
		self.fontDescriptors = fontDescriptors;

	}
	return self;
}

#pragma mark -
#pragma mark Propery Overrides

- (MADReportTextRepresentation *)textRepresentation {
	if (_textRepresentation == nil) {
		_textRepresentation = [[MADReportTextRepresentation alloc] initWithPageCount: (NSUInteger)self.datasource.reportFormatter.reportLayout.count];
	}
	return _textRepresentation;
}

- (NSDictionary <NSString *, id> *)fontAttributes:(MADDocumentObjectDataReference *)dataRef {
	__kindof RptqDocumentElement *item = dataRef.item;
	MADElementStylizedText *attt = self.fontDescriptors[@(item.identifier)];
	if (attt == nil) {
		attt = [[MADElementStylizedText alloc] initWithFontName: item.fontname
													   fontSize: item.fontsize
													  textStyle: item.textStyle
											horizontalAlignment: item.alignment.horizontal];
		
		self.fontDescriptors[@(item.identifier)] = attt;
	}
	return attt.fontAttributes;
}

#pragma mark -
#pragma mark Drawing Helpers

+ (UIColor *)backgroundColorForDocumentSectionType:(MADDocumentSectionType)type {
	switch (type) {
		case MADDocumentSectionTypeBody:
			return [UIColor redColor];
			break;
			
		case MADDocumentSectionTypeGroupFooter:
			return [UIColor purpleColor];
			break;
			
		case MADDocumentSectionTypeGroupHeader:
			return [UIColor yellowColor];
			break;
			
		case MADDocumentSectionTypePageFooter:
			return [UIColor grayColor];
			break;
			
		case MADDocumentSectionTypePageHeader:
			return [UIColor greenColor];
			break;
			
		case MADDocumentSectionTypeReportFooter:
			return [UIColor brownColor];
			break;
			
		case MADDocumentSectionTypeReportHeader:
			return [UIColor blueColor];
			break;
			
		default:
			return [UIColor magentaColor];
			break;
	}
}

- (void)setBackgroundColorForDocumentSection:(RptqDocumentSection *)documentSection
									  inRect:(CGRect)rect {

	CGContextRef ctx = UIGraphicsGetCurrentContext();
	[[UIColor whiteColor] setFill];
	
	switch ([documentSection getDocumentSectionType]) {
		case MADDocumentSectionTypeBody:
			[[UIColor redColor] setFill];
			break;
			
		case MADDocumentSectionTypeGroupFooter:
			[[UIColor purpleColor] setFill];
			break;
			
		case MADDocumentSectionTypeGroupHeader:
			[[UIColor yellowColor] setFill];
			break;
			
		case MADDocumentSectionTypePageFooter:
			[[UIColor grayColor] setFill];
			break;
			
		case MADDocumentSectionTypePageHeader:
			[[UIColor greenColor] setFill];
			break;
			
		case MADDocumentSectionTypeReportFooter:
			[[UIColor brownColor] setFill];
			break;
			
		case MADDocumentSectionTypeReportHeader:
			[[UIColor blueColor] setFill];
			break;
			
		default:
			[[UIColor magentaColor] setFill];
			break;
	}
	
	CGPathRef path = CGPathCreateWithRect(rect, NULL);
	CGContextAddPath(ctx, path);
	CGContextDrawPath(ctx, kCGPathFill);
	CGPathRelease(path);

}

#pragma mark -
#pragma mark Drawing loop

- (void)drawPageAtIndex:(NSUInteger)index inRect:(CGRect)pageRect
					   withTransparentBackground:(BOOL)transparentBackground {

	CGContextRef ctx = UIGraphicsGetCurrentContext();
	// The header's contract: a transparent page is the page's own drawing over
	// whatever the caller's context already holds, with no white canvas behind it.
	if (!transparentBackground) [MADPrintPageRenderer drawWhiteCanvas: ctx pageRect: pageRect];
	[self drawPageAtIndex: index withContext: ctx inPageRect: pageRect];
}

- (void)drawPageAtIndex:(NSUInteger)pageIndex
			withContext:(CGContextRef)ctx
			 inPageRect:(CGRect)pageRect {
	[self buildPageAtIndex: pageIndex context: ctx inPageRect: pageRect];
}

// The walk is MADReportPageBuilder's -- the same one the formats that draw nothing
// read -- and this method is the renderer's half of it: the font-descriptor cache the
// elements draw through, the drawing block when there is a context to draw into, and
// the text representation the page is recorded in either way.  A caller that only
// wants the structure passes NULL and reads what comes back (MADPrintPageRenderer.h;
// MAD_LINUX.md §9 Phase E).
- (MADReportPageRepresentation *)buildPageAtIndex:(NSUInteger)pageIndex
										  context:(CGContextRef)ctx
									   inPageRect:(CGRect)pageRect {

	MADReportPageBuilder *builder = self.pageBuilder;
	builder.styler = self;

	MADReportPageRepresentation *pageRepresentation = nil;
	if (ctx != NULL) {
		pageRepresentation = [builder buildPageAtIndex: pageIndex
											inPageRect: pageRect
												  draw: ^(MADPrintPageElement *element, CGRect frame) {
			[element drawInRect: frame];
		}];
	} else {
		pageRepresentation = [builder buildPageAtIndex: pageIndex inPageRect: pageRect draw: NULL];
	}

	if (pageRepresentation != nil) {
		[self.textRepresentation removeAllPages];
		[self.textRepresentation setPage: pageRepresentation forPageIndex: pageIndex];
	}

	return pageRepresentation;
}

- (MADReportPageBuilder *)pageBuilder {
	if (_pageBuilder == nil) {
		_pageBuilder = [[MADReportPageBuilder alloc] initWithDataSource: self.datasource];
	}
	return _pageBuilder;
}

+ (void)setBackgroundColorForSectionType:(MADDocumentSectionType)type inRect:(CGRect)rect {
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	[[self backgroundColorForDocumentSectionType:type] setFill];
	CGPathRef path = CGPathCreateWithRect(rect, NULL);
	CGContextAddPath(ctx, path);
	CGContextDrawPath(ctx, kCGPathFill);
	CGPathRelease(path);
}

#pragma mark -
#pragma mark UIPrintPageRender

- (NSInteger)numberOfPages {
	return (NSInteger)(self.datasource.reportFormatter).numberOfPages;
}

- (void)drawPageAtIndex:(NSInteger)index inRect:(CGRect)pageRect {
	[self drawPageAtIndex: (unsigned long)labs(index) inRect: pageRect withTransparentBackground: NO];
}

- (void)drawHeaderForPageAtIndex:(NSInteger)index inRect:(CGRect)headerRect {
	[super drawHeaderForPageAtIndex: index
							 inRect: headerRect];
}

- (void)drawContentForPageAtIndex:(NSInteger)index inRect:(CGRect)contentRect {
	[super drawContentForPageAtIndex: index
							  inRect: contentRect];
}

- (void)drawFooterForPageAtIndex:(NSInteger)index inRect:(CGRect)footerRect {
	[super drawFooterForPageAtIndex: index
							 inRect: footerRect];
}

#pragma mark

- (id)debugQuickLookObject {
	return self.textRepresentation;
}

/*- (void)updateAccessibilityItems {
	if (!self.accessibilityCacheNeedsUpdate) return;
	NSArray *items = [self accessibilityDrawingObjectsOnPageAtIndex:self.accessibilityCurrentPageIndex inPageRect:self.accessibilityCurrentPageRect];
	self.accessibilityItems = [NSArray arrayWithArray:items];
	self.accessibilityCacheNeedsUpdate = NO;
}*/
/*
NSComparator accessibilityLineComparson = ^NSComparisonResult(MADAccessibilityLine *  _Nonnull obj1, MADAccessibilityLine *  _Nonnull obj2) {
	// Sort from left to right.
	if (obj1.frame.origin.y < obj2.frame.origin.y) {
		return NSOrderedAscending;
	} else if (obj1.frame.origin.y == obj2.frame.origin.y && obj1.frame.origin.x < obj2.frame.origin.x) {
		return NSOrderedAscending;
	} else {
		return NSOrderedDescending;
	}
};

// FIXME: This is the start of an attempt at a seperate accessibility run.
//  May store this stuff off seperately on og pass, and use UITextInput protocol.

- (NSArray *)accessibilityDrawingObjectsOnPageAtIndex:(NSUInteger)pageIndex inPageRect:(CGRect)pageRect {
	NSUInteger rowIndex = 0, layoutSectionCounter = 0, readGroupCounter = 0;
	NSMutableArray *accessibilityDrawingObjects = [[NSMutableArray alloc] init];
	
	RptqDocument *document = [self.reportFormatter.layout activeDocumentModel];
	RptqDatabase *databaseSchemas = document.hasDatabaseSchemas.anyObject;
	
	MADDatabaseConnection *databaseConnection = [MADDatabaseConnection newDatabaseConnectionForUserCredentals:databaseSchemas.ownedByUser];
	MADDatabase *database = [MADDatabase newDatabaseWithConnection:databaseConnection];
	
	NSUInteger numberOfPages = self.reportFormatter.numberOfPages;
	if (pageIndex < numberOfPages) {
		
		CGFloat originY = pageRect.origin.y;
		NSEnumerator *layoutEnumerator = [self.reportFormatter layoutEnumerator:pageIndex];
		for (NSDictionary *pageSection in layoutEnumerator) {
			
			RptqDocumentSection *documentSection = [document documentSectionForType:pageSection.sectionType andLevel:pageSection.groupLevel];
			
			CGRect sectionRect = [self sectionRectForDocumentSection:documentSection pageSection:pageSection inDocument:document pageRect:pageRect numberOfPages:numberOfPages pageIndex:pageIndex offset:&originY];
			
			self.backgroundColorForDocumentSection:documentSection inRect:sectionRect];
			
			NSArray *groupLevelKeys = [self newObjectArrayOfGroupLevelKeysForDetailRow:pageSection.detailRowId];
			if (pageSection.sectionType == MADDocumentSectionTypeGroupFooter && pageSection.groupLevel == self.reportFormatter.numberOfGroups - 1) {
				readGroupCounter++;
			}
			if (documentSection.visibility.boolValue) {
				
				NSMutableArray *accessibilityLinesInSection = [[NSMutableArray alloc] init];
				for (RptqDocumentSectionRows *row in documentSection.hasRows) {
					for (RptqDocumentElement *item in row.hasObjects) {
						@autoreleasepool {
							id drawingObject = [self newDrawingObjectForDatabase:database pageIndex:pageIndex groupLevelKeys:groupLevelKeys detailRowId:pageSection.detailRowId andItem:item];
							MADAccessibilityLine *line = [[MADAccessibilityLine alloc] initWithValue:drawingObject
																								type:item.documentObjectType
																							andFrame:CGRectMake(item.originx.floatValue + sectionRect.origin.x + item.spacingLeft,
																																	   item.originy.floatValue + sectionRect.origin.y + item.spacingTop,
																																	   item.sizewidth.floatValue + item.spacingRight,
																																	   item.sizeheight.floatValue + item.spacingBottom)];
							[accessibilityLinesInSection addObject:line];
						}
					}
				}
				[accessibilityLinesInSection sortUsingComparator:accessibilityLineComparson];
				[accessibilityDrawingObjects addObjectsFromArray:accessibilityLinesInSection];

			}
			
			if (pageSection.sectionType == MADDocumentSectionTypeBody) {
				rowIndex++;
			}
			originY += sectionRect.size.height;
		}
		layoutSectionCounter++;
	}
	return accessibilityDrawingObjects;
}
*/
/*
+ (void)displayDrawingObject: (id *)drawingObject
					 forItem: (CGRect)itemFrame
			   inSectionRect: (CGRect)sectionRect {

	CGRect elementCanvasRect = item.frame;
	elementCanvasRect.origin.x = elementCanvasRect.origin.x + sectionRect.origin.x;
	elementCanvasRect.origin.y = elementCanvasRect.origin.y + sectionRect.origin.y;
	
	if ([drawingObject isKindOfClass:[NSString class]]) {
		
		UIFontDescriptor *fontDescriptor = [item newFontDescriptor];
		NSDictionary *attributes = [item newTextAttributesWithFontDescriptor:fontDescriptor];
		[drawingObject drawWithRect: elementCanvasRect
							options: NSStringDrawingUsesLineFragmentOrigin
						 attributes: attributes context: nil];
		attributes = nil;
		
	} else {
		[drawingObject drawInRect:elementCanvasRect];
	}
}
*/

@end
