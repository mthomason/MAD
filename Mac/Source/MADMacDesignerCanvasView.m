//
//  MADMacDesignerCanvasView.m
//  MAD Designer (macOS Native)
//

#import "MADMacDesignerCanvasView.h"
#import "MADMacDocument.h"

#import <MAD/MAD.h>
#import <MADBarcodes/MADBarcodes.h>

NSPasteboardType const MADMacDesignerPasteboardTypeQueryField = @"com.mobileanalytics.mad.designer.query-field";
NSPasteboardType const MADMacDesignerPasteboardTypeElementKind = @"com.mobileanalytics.mad.designer.element-kind";

typedef NS_ENUM(NSInteger, MADMacCanvasDragMode) {
	MADMacCanvasDragModeNone = 0,
	MADMacCanvasDragModeMoveElement,
	MADMacCanvasDragModeResizeElement,
	MADMacCanvasDragModeResizeSection,
	MADMacCanvasDragModeMarquee
};

typedef NS_ENUM(NSInteger, MADMacResizeHandle) {
	MADMacResizeHandleNone = 0,
	MADMacResizeHandleTopLeft,
	MADMacResizeHandleTop,
	MADMacResizeHandleTopRight,
	MADMacResizeHandleRight,
	MADMacResizeHandleBottomRight,
	MADMacResizeHandleBottom,
	MADMacResizeHandleBottomLeft,
	MADMacResizeHandleLeft
};

static const CGFloat kCanvasOuterMargin = 28.0;
static const CGFloat kRulerTopHeight = 20.0;
static const CGFloat kSectionHeaderHeight = 24.0;
static const CGFloat kSectionResizeBarHeight = 7.0;
static const CGFloat kSectionGap = 12.0;
static const CGFloat kSnapThreshold = 4.5;

@interface MADMacDesignerCanvasView () <NSTextFieldDelegate>
@property (nonatomic, strong) NSMutableOrderedSet<RptqDocumentElement *> *mutableSelectedElements;
@property (nonatomic, assign) MADMacCanvasDragMode dragMode;
@property (nonatomic, assign) MADMacResizeHandle activeResizeHandle;
@property (nonatomic, strong, nullable) RptqDocumentElement *dragElement;
@property (nonatomic, strong, nullable) RptqDocumentSection *dragSourceSection;
@property (nonatomic, strong, nullable) RptqDocumentSection *dragHoverSection;
@property (nonatomic, assign) NSPoint dragStartPointInCanvas;
@property (nonatomic, assign) NSRect dragInitialElementRect;
@property (nonatomic, assign) NSPoint dragGrabOffsetInElement;
@property (nonatomic, strong, nullable) NSMapTable<RptqDocumentElement *, NSValue *> *dragInitialOriginsByElement;
@property (nonatomic, strong, nullable) NSMapTable<RptqDocumentElement *, RptqDocumentSection *> *dragInitialSectionsByElement;
@property (nonatomic, assign) NSPoint dragLiveOriginInHoverSection;
@property (nonatomic, assign) BOOL dragHasMovedSignificantly;

@property (nonatomic, strong, nullable) RptqDocumentSection *resizingSection;
@property (nonatomic, assign) CGFloat dragInitialSectionHeight;

@property (nonatomic, assign) NSRect marqueeRectInCanvas;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *activeVerticalGuides;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *activeHorizontalGuides;

@property (nonatomic, strong, nullable) RptqDocumentSection *dropTargetSection;
@property (nonatomic, assign) NSPoint dropTargetPointInSection;
@property (nonatomic, assign) BOOL hasActiveDropTarget;

@property (nonatomic, strong, nullable) NSTextField *inlineEditorField;
@property (nonatomic, strong, nullable) RptqDocumentElementLabel *inlineEditingLabel;
@property (nonatomic, copy, nullable) NSString *inlineEditingOriginalText;
@property (nonatomic, strong, nullable) NSTrackingArea *canvasTrackingArea;
@end

@implementation MADMacDesignerCanvasView

- (instancetype)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self) {
		_zoomScale = 1.0;
		_showGrid = YES;
		_snapToGrid = YES;
		_showRulers = YES;
		_gridSpacing = 8.0;
		_mutableSelectedElements = [NSMutableOrderedSet orderedSet];
		_activeVerticalGuides = [NSMutableArray array];
		_activeHorizontalGuides = [NSMutableArray array];
		[self registerForDraggedTypes:@[
			MADMacDesignerPasteboardTypeQueryField,
			MADMacDesignerPasteboardTypeElementKind,
			NSPasteboardTypeString
		]];
	}
	return self;
}

- (BOOL)isFlipped {
	return YES;
}

- (BOOL)acceptsFirstResponder {
	return YES;
}

- (void)updateTrackingAreas {
	[super updateTrackingAreas];
	if (_canvasTrackingArea) {
		[self removeTrackingArea:_canvasTrackingArea];
	}
	NSTrackingAreaOptions opts = (NSTrackingMouseMoved | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect);
	_canvasTrackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:opts owner:self userInfo:nil];
	[self addTrackingArea:_canvasTrackingArea];
}

#pragma mark - Selection & Properties

- (NSOrderedSet<RptqDocumentElement *> *)selectedElements {
	return [_mutableSelectedElements copy];
}

- (RptqDocumentElement *)primarySelectedElement {
	return _mutableSelectedElements.firstObject;
}

- (void)setZoomScale:(CGFloat)zoomScale {
	CGFloat clamped = MAX(0.5, MIN(2.5, zoomScale));
	if (fabs(_zoomScale - clamped) < 0.001) return;
	_zoomScale = clamped;
	[self recalculateCanvasSize];
	[self setNeedsDisplay:YES];
}

- (void)setShowGrid:(BOOL)showGrid {
	_showGrid = showGrid;
	[self setNeedsDisplay:YES];
}

- (void)setShowRulers:(BOOL)showRulers {
	_showRulers = showRulers;
	[self recalculateCanvasSize];
	[self setNeedsDisplay:YES];
}

- (void)selectElement:(RptqDocumentElement *)element extendSelection:(BOOL)extend {
	[self commitInlineEditingIfNeeded];
	if (!extend) {
		[_mutableSelectedElements removeAllObjects];
	}
	if (element) {
		if (extend && [_mutableSelectedElements containsObject:element]) {
			[_mutableSelectedElements removeObject:element];
		} else {
			[_mutableSelectedElements addObject:element];
		}
		RptqDocumentSection *sec = [self sectionContainingElement:element];
		if (sec) {
			_selectedSection = sec;
		}
	}
	[self setNeedsDisplay:YES];
	if ([self.delegate respondsToSelector:@selector(designerCanvasSelectionDidChange:)]) {
		[self.delegate designerCanvasSelectionDidChange:self];
	}
}

- (void)setSelectedElementsSet:(NSOrderedSet<RptqDocumentElement *> *)elements {
	[self commitInlineEditingIfNeeded];
	[_mutableSelectedElements removeAllObjects];
	if (elements.count > 0) {
		[_mutableSelectedElements addObjectsFromArray:elements.array];
		RptqDocumentSection *sec = [self sectionContainingElement:elements.firstObject];
		if (sec) {
			_selectedSection = sec;
		}
	}
	[self setNeedsDisplay:YES];
	if ([self.delegate respondsToSelector:@selector(designerCanvasSelectionDidChange:)]) {
		[self.delegate designerCanvasSelectionDidChange:self];
	}
}

- (void)clearElementSelection {
	[self commitInlineEditingIfNeeded];
	[_mutableSelectedElements removeAllObjects];
	[self setNeedsDisplay:YES];
	if ([self.delegate respondsToSelector:@selector(designerCanvasSelectionDidChange:)]) {
		[self.delegate designerCanvasSelectionDidChange:self];
	}
}

- (void)selectAllElementsInSelectedSection {
	[self commitInlineEditingIfNeeded];
	RptqDocumentSection *sec = self.selectedSection ?: [self orderedSections].firstObject;
	if (!sec) return;
	_selectedSection = sec;
	[_mutableSelectedElements removeAllObjects];
	[_mutableSelectedElements addObjectsFromArray:[self elementsInSection:sec]];
	[self setNeedsDisplay:YES];
	if ([self.delegate respondsToSelector:@selector(designerCanvasSelectionDidChange:)]) {
		[self.delegate designerCanvasSelectionDidChange:self];
	}
}

#pragma mark - Document Geometry & Section Helpers

- (NSArray<RptqDocumentSection *> *)orderedSections {
	MADMacDocument *doc = self.document;
	return doc ? ([doc orderedSections] ?: @[]) : @[];
}

- (CGFloat)paperWidth {
	MADMacDocument *doc = self.document;
	RptqDocument *rptqDoc = doc.rptqDocument;
	if (rptqDoc) {
		CGSize sz = [MTPaper sizeForType:(MTPaperType)rptqDoc.papersize];
		if (sz.width > 100.0) {
			return sz.width;
		}
	}
	return 612.0;
}

- (CGFloat)leftMargin {
	return 18.0;
}

- (CGFloat)rightMargin {
	return 18.0;
}

- (CGFloat)contentHeightForSection:(RptqDocumentSection *)section {
	if (!section.visibility) {
		return 24.0;
	}
	CGFloat total = (CGFloat)section.layoutHeight;
	if (total < 32.0) {
		total = MAX(36.0, (CGFloat)section.height - 44.0);
	}
	for (RptqDocumentSectionRows *row in section.hasRows) {
		if (row.layoutHeight > total) {
			total = row.layoutHeight;
		}
		for (RptqDocumentElement *el in row.hasObjects) {
			NSRect r = [self elementRectInSectionContent:el];
			CGFloat bottom = MAX(0.0, NSMaxY(r)) + 6.0;
			if (bottom > total) total = bottom;
		}
	}
	return MAX(32.0, total);
}

- (RptqDocumentSectionRows *)ensureFirstRowForSection:(RptqDocumentSection *)section {
	if (!section) return nil;
	if (section.hasRows.count > 0) {
		return section.hasRows.firstObject;
	}
	MADMacDocument *doc = self.document;
	RptqStoreContext *ctx = doc.managedObjectContext;
	if (!ctx) return nil;
	RptqDocumentSectionRows *row = (RptqDocumentSectionRows *)[ctx insertObjectForEntity:NSStringFromClass([RptqDocumentSectionRows class]) identifier:0];
	row.rowNumber = 0;
	row.layoutHeight = MAX(40.0, section.layoutHeight);
	row.inSection = section;
	[section addHasRowsFixed:row];
	return row;
}

- (void)recalculateCanvasSize {
	NSArray<RptqDocumentSection *> *sections = [self orderedSections];
	CGFloat paperW = [self paperWidth];
	CGFloat rulerExtra = _showRulers ? (kRulerTopHeight + 6.0) : 0.0;
	CGFloat y = kCanvasOuterMargin + rulerExtra;
	for (RptqDocumentSection *sec in sections) {
		CGFloat contentH = [self contentHeightForSection:sec];
		y += kSectionHeaderHeight + contentH + kSectionResizeBarHeight + kSectionGap;
	}
	y += kCanvasOuterMargin;
	CGFloat unscaledW = paperW + kCanvasOuterMargin * 2.0;
	CGFloat scaledW = ceil(unscaledW * _zoomScale);
	CGFloat scaledH = ceil(MAX(420.0, y * _zoomScale));

	NSScrollView *enclosing = self.enclosingScrollView;
	if (enclosing) {
		NSSize clipSize = enclosing.contentView.bounds.size;
		scaledW = MAX(scaledW, clipSize.width);
		scaledH = MAX(scaledH, clipSize.height);
	}
	[self setFrameSize:NSMakeSize(scaledW, scaledH)];
	[self updateInlineEditorFrameIfNeeded];
}

- (void)updateInlineEditorFrameIfNeeded {
	if (!_inlineEditorField || !_inlineEditingLabel) return;
	RptqDocumentSection *sec = [self sectionContainingElement:_inlineEditingLabel];
	if (!sec) return;
	NSRect contentRect = [self sectionContentRectForSection:sec];
	NSRect elRect = [self elementRectInSectionContent:_inlineEditingLabel];
	NSRect unscaledRect = NSMakeRect(contentRect.origin.x + elRect.origin.x,
									 contentRect.origin.y + elRect.origin.y,
									 MAX(40.0, elRect.size.width),
									 MAX(18.0, elRect.size.height));
	NSRect viewRect = NSMakeRect(unscaledRect.origin.x * _zoomScale,
								 unscaledRect.origin.y * _zoomScale,
								 unscaledRect.size.width * _zoomScale,
								 unscaledRect.size.height * _zoomScale);
	_inlineEditorField.frame = NSInsetRect(viewRect, -2.0, -2.0);
}

- (CGFloat)paperOriginX {
	CGFloat paperW = [self paperWidth];
	CGFloat viewUnscaledW = self.bounds.size.width / _zoomScale;
	return MAX(kCanvasOuterMargin, floor((viewUnscaledW - paperW) * 0.5));
}

- (NSRect)sectionBandRectForSection:(RptqDocumentSection *)targetSection {
	NSArray<RptqDocumentSection *> *sections = [self orderedSections];
	CGFloat paperW = [self paperWidth];
	CGFloat x = [self paperOriginX];
	CGFloat y = kCanvasOuterMargin + (_showRulers ? (kRulerTopHeight + 6.0) : 0.0);
	for (RptqDocumentSection *sec in sections) {
		CGFloat contentH = [self contentHeightForSection:sec];
		CGFloat bandH = kSectionHeaderHeight + contentH + kSectionResizeBarHeight;
		if ([sec isEqual:targetSection]) {
			return NSMakeRect(x, y, paperW, bandH);
		}
		y += bandH + kSectionGap;
	}
	return NSZeroRect;
}

- (NSRect)sectionContentRectForSection:(RptqDocumentSection *)targetSection {
	NSRect band = [self sectionBandRectForSection:targetSection];
	if (NSIsEmptyRect(band)) return NSZeroRect;
	CGFloat leftM = [self leftMargin];
	CGFloat rightM = [self rightMargin];
	CGFloat contentW = MAX(40.0, band.size.width - leftM - rightM);
	CGFloat contentH = band.size.height - kSectionHeaderHeight - kSectionResizeBarHeight;
	return NSMakeRect(band.origin.x + leftM, band.origin.y + kSectionHeaderHeight, contentW, contentH);
}

- (NSRect)elementRectInSectionContent:(RptqDocumentElement *)element {
	if (!element) return NSZeroRect;
	CGFloat x = (element.rect && element.rect.origin) ? element.rect.origin.x : 0.0;
	CGFloat y = (element.rect && element.rect.origin) ? element.rect.origin.y : 0.0;
	if (x == 0.0 && y == 0.0 && element.dropPoint && (element.dropPoint.x != 0.0 || element.dropPoint.y != 0.0)) {
		x = element.dropPoint.x;
		y = element.dropPoint.y;
	}
	CGFloat w = (element.rect && element.rect.size && element.rect.size.width > 0) ? element.rect.size.width : 120.0;
	CGFloat h = (element.rect && element.rect.size && element.rect.size.height > 0) ? element.rect.size.height : 22.0;
	return NSMakeRect(x, y, w, h);
}

- (void)setElement:(RptqDocumentElement *)element originInSectionContent:(NSPoint)origin {
	if (!element) return;
	CGFloat clampedX = MAX(0.0, round(origin.x * 2.0) / 2.0);
	CGFloat clampedY = MAX(0.0, round(origin.y * 2.0) / 2.0);
	[element setOriginPoint:CGPointMake(clampedX, clampedY)];
	if (element.dropPoint) {
		element.dropPoint.x = (float)clampedX;
		element.dropPoint.y = (float)clampedY;
	}
}

- (NSPoint)nextAvailableOriginInSection:(RptqDocumentSection *)section forElementSize:(NSSize)size {
	if (!section) return NSMakePoint(16.0, 10.0);
	NSArray<RptqDocumentElement *> *existing = [self elementsInSection:section];
	if (existing.count == 0) {
		return NSMakePoint(16.0, 10.0);
	}
	NSRect contentRect = [self sectionContentRectForSection:section];
	CGFloat maxWidth = contentRect.size.width > 0 ? contentRect.size.width : ([self paperWidth] - [self leftMargin] - [self rightMargin]);

	// Find the element on the lowest row (largest Y, then largest maxX on that row).
	CGFloat bottomRowY = 10.0;
	for (RptqDocumentElement *el in existing) {
		NSRect r = [self elementRectInSectionContent:el];
		if (r.origin.y > bottomRowY + 4.0) {
			bottomRowY = r.origin.y;
		}
	}

	CGFloat rightmostOnBottomRow = 16.0;
	CGFloat maxBottomEdge = 10.0;
	for (RptqDocumentElement *el in existing) {
		NSRect r = [self elementRectInSectionContent:el];
		if (NSMaxY(r) > maxBottomEdge) {
			maxBottomEdge = NSMaxY(r);
		}
		if (fabs(r.origin.y - bottomRowY) <= 10.0) {
			if (NSMaxX(r) > rightmostOnBottomRow) {
				rightmostOnBottomRow = NSMaxX(r);
			}
		}
	}

	CGFloat candidateX = rightmostOnBottomRow + 12.0;
	CGFloat candidateY = bottomRowY;
	if (candidateX + size.width > maxWidth - 8.0) {
		candidateX = 16.0;
		candidateY = maxBottomEdge + 8.0;
	}

	if (_snapToGrid && _gridSpacing > 1.0) {
		candidateX = round(candidateX / _gridSpacing) * _gridSpacing;
		candidateY = round(candidateY / _gridSpacing) * _gridSpacing;
	}

	// Ensure no overlap with existing elements.
	for (NSInteger attempt = 0; attempt < 24; attempt++) {
		NSRect testRect = NSMakeRect(candidateX, candidateY, size.width, size.height);
		BOOL overlaps = NO;
		for (RptqDocumentElement *el in existing) {
			NSRect r = [self elementRectInSectionContent:el];
			if (NSIntersectsRect(NSInsetRect(testRect, 2.0, 2.0), r)) {
				overlaps = YES;
				break;
			}
		}
		if (!overlaps) break;
		candidateX += 16.0;
		if (candidateX + size.width > maxWidth - 8.0) {
			candidateX = 16.0;
			candidateY += MAX(16.0, size.height + 6.0);
		}
	}

	if (candidateY + size.height + 8.0 > [self contentHeightForSection:section]) {
		[section setInterfaceHeight:ceil(candidateY + size.height + 10.0)];
	}
	return NSMakePoint(MAX(0.0, candidateX), MAX(0.0, candidateY));
}

- (BOOL)moveElement:(RptqDocumentElement *)element
		  toSection:(RptqDocumentSection *)targetSection
		   atOrigin:(NSPoint)origin {
	if (!element || !targetSection) return NO;
	RptqDocumentSection *currentSection = [self sectionContainingElement:element];
	RptqDocumentSectionRows *targetRow = [self ensureFirstRowForSection:targetSection];
	if (!targetRow) return NO;

	if (![currentSection isEqual:targetSection]) {
		for (RptqDocumentSection *sec in [self orderedSections]) {
			for (RptqDocumentSectionRows *row in sec.hasRows) {
				if ([row.hasObjects containsObject:element]) {
					[row removeHasObjectsObject:element];
				}
			}
		}
		[targetRow addHasObjectsObject:element];
		element.inSectionRow = targetRow;
	}

	NSRect contentRect = [self sectionContentRectForSection:targetSection];
	NSRect elRect = [self elementRectInSectionContent:element];
	CGFloat maxX = MAX(0.0, contentRect.size.width - elRect.size.width);
	NSPoint clampedOrigin = NSMakePoint(MAX(0.0, MIN(maxX, origin.x)), MAX(0.0, origin.y));
	[self setElement:element originInSectionContent:clampedOrigin];

	if (clampedOrigin.y + elRect.size.height + 6.0 > [self contentHeightForSection:targetSection]) {
		[targetSection setInterfaceHeight:ceil(clampedOrigin.y + elRect.size.height + 8.0)];
	}
	[self recalculateCanvasSize];
	[self setNeedsDisplay:YES];
	return YES;
}

- (RptqDocumentSection *)sectionContainingElement:(RptqDocumentElement *)element {
	if (!element) return nil;
	if (element.inSectionRow && element.inSectionRow.inSection) {
		return element.inSectionRow.inSection;
	}
	for (RptqDocumentSection *sec in [self orderedSections]) {
		for (RptqDocumentSectionRows *row in sec.hasRows) {
			if ([row.hasObjects containsObject:element]) {
				return sec;
			}
		}
	}
	return nil;
}

- (NSArray<RptqDocumentElement *> *)elementsInSection:(RptqDocumentSection *)section {
	if (!section) return @[];
	NSMutableArray<RptqDocumentElement *> *items = [NSMutableArray array];
	for (RptqDocumentSectionRows *row in section.hasRows) {
		if (row.hasObjects) {
			[items addObjectsFromArray:row.hasObjects.array];
		}
	}
	return items;
}

- (void)scrollToSection:(RptqDocumentSection *)section {
	if (!section) return;
	NSRect band = [self sectionBandRectForSection:section];
	if (NSIsEmptyRect(band)) return;
	NSRect scaled = NSMakeRect(band.origin.x * _zoomScale,
							   MAX(0.0, (band.origin.y - 16.0) * _zoomScale),
							   band.size.width * _zoomScale,
							   (band.size.height + 32.0) * _zoomScale);
	[self scrollRectToVisible:scaled];
}
#pragma mark - Section Appearance & Display Titles

+ (NSColor *)accentColorForSection:(RptqDocumentSection *)section {
	switch ((MADDocumentSectionType)section.type) {
		case MADDocumentSectionTypeReportHeader:
		case MADDocumentSectionTypeReportFooter:
			return [NSColor systemBlueColor];
		case MADDocumentSectionTypePageHeader:
		case MADDocumentSectionTypePageFooter:
			return [NSColor systemPurpleColor];
		case MADDocumentSectionTypeGroupHeader:
		case MADDocumentSectionTypeGroupFooter:
			return [NSColor systemOrangeColor];
		case MADDocumentSectionTypeBody:
		default:
			return [NSColor systemTealColor];
	}
}

+ (NSString *)shortBadgeForSection:(RptqDocumentSection *)section {
	switch ((MADDocumentSectionType)section.type) {
		case MADDocumentSectionTypeReportHeader: return @"RH";
		case MADDocumentSectionTypePageHeader:   return @"PH";
		case MADDocumentSectionTypeGroupHeader:  return @"GRP▲";
		case MADDocumentSectionTypeBody:         return @"DTL";
		case MADDocumentSectionTypeGroupFooter:  return @"GRP▼";
		case MADDocumentSectionTypePageFooter:   return @"PF";
		case MADDocumentSectionTypeReportFooter: return @"RF";
		default:                                 return @"SEC";
	}
}

- (NSString *)displayTitleForElement:(RptqDocumentElement *)element {
	if ([element isKindOfClass:[RptqDocumentElementLabel class]]) {
		RptqDocumentElementLabel *lbl = (RptqDocumentElementLabel *)element;
		return lbl.text.length > 0 ? lbl.text : @"Static Label";
	}
	if ([element isKindOfClass:[RptqDocumentElementLabelDataField class]]) {
		RptqDocumentElementLabelDataField *dl = (RptqDocumentElementLabelDataField *)element;
		if (dl.text.length > 0) return dl.text;
		NSString *col = dl.fieldID ?: dl.referencesQueryField.databaseSchemaField.name ?: @"Unbound";
		return [NSString stringWithFormat:@"[%@]", col];
	}
	if ([element isKindOfClass:[RptqDocumentElementAggregate class]]) {
		RptqDocumentElementAggregate *agg = (RptqDocumentElementAggregate *)element;
		NSString *repr = [agg designerRepresentationText];
		if (repr.length > 0) return repr;
		return @"AGG(...)";
	}
	if ([element isKindOfClass:[RptqDocumentElementBarcode class]]) {
		RptqDocumentElementBarcode *bc = (RptqDocumentElementBarcode *)element;
		NSString *val = (bc.useStaticInput1 && bc.inputStatic1.length > 0)
			? bc.inputStatic1
			: (bc.referencesField1.databaseSchemaField.name ?: @"12345678");
		return [NSString stringWithFormat:@"Barcode: %@", val];
	}
	if ([element isKindOfClass:[RptqDocumentElementImage class]]) {
		return @"Image";
	}
	NSString *repr = [element designerRepresentationText];
	return repr.length > 0 ? repr : @"Element";
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect {
	[[NSColor underPageBackgroundColor] setFill];
	NSRectFill(dirtyRect);

	NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
	[ctx saveGraphicsState];

	NSAffineTransform *xform = [NSAffineTransform transform];
	[xform scaleBy:_zoomScale];
	[xform concat];

	NSArray<RptqDocumentSection *> *sections = [self orderedSections];
	if (_showRulers && sections.count > 0) {
		[self drawTopHorizontalRuler];
	}

	for (RptqDocumentSection *sec in sections) {
		[self drawSectionBand:sec];
	}

	// Draw cross-section floating preview when dragging elements into a different section.
	if (_dragMode == MADMacCanvasDragModeMoveElement &&
		_dragElement &&
		_dragHoverSection &&
		![_dragHoverSection isEqual:_dragSourceSection]) {
		NSRect hoverContent = [self sectionContentRectForSection:_dragHoverSection];
		NSPoint primaryInitial = _dragInitialElementRect.origin;
		CGFloat dx = _dragLiveOriginInHoverSection.x - primaryInitial.x;
		CGFloat dy = _dragLiveOriginInHoverSection.y - primaryInitial.y;
		for (RptqDocumentElement *el in _mutableSelectedElements) {
			NSValue *initVal = [_dragInitialOriginsByElement objectForKey:el];
			NSPoint elInit = initVal ? initVal.pointValue : [self elementRectInSectionContent:el].origin;
			NSRect elSizeRect = [self elementRectInSectionContent:el];
			NSRect ghostRect = NSMakeRect(hoverContent.origin.x + MAX(0.0, elInit.x + dx),
										  hoverContent.origin.y + MAX(0.0, elInit.y + dy),
										  elSizeRect.size.width,
										  elSizeRect.size.height);
			[[[NSColor controlAccentColor] colorWithAlphaComponent:0.16] setFill];
			NSBezierPath *ghostPath = [NSBezierPath bezierPathWithRoundedRect:ghostRect xRadius:2.0 yRadius:2.0];
			[ghostPath fill];
			[[NSColor controlAccentColor] setStroke];
			CGFloat dash[2] = { 4.0, 2.5 };
			[ghostPath setLineDash:dash count:2 phase:0.0];
			ghostPath.lineWidth = 1.5;
			[ghostPath stroke];
		}
	}

	// Draw smart alignment guides.
	if ((_dragMode == MADMacCanvasDragModeMoveElement || _dragMode == MADMacCanvasDragModeResizeElement) &&
		(_activeVerticalGuides.count > 0 || _activeHorizontalGuides.count > 0)) {
		[[NSColor systemPinkColor] setStroke];
		CGFloat paperX = [self paperOriginX];
		CGFloat leftM = [self leftMargin];
		CGFloat totalH = self.bounds.size.height / _zoomScale;
		for (NSNumber *gx in _activeVerticalGuides) {
			CGFloat canvasX = paperX + leftM + gx.doubleValue;
			NSBezierPath *line = [NSBezierPath bezierPath];
			[line moveToPoint:NSMakePoint(canvasX + 0.5, kCanvasOuterMargin)];
			[line lineToPoint:NSMakePoint(canvasX + 0.5, totalH - kCanvasOuterMargin)];
			CGFloat dash[2] = { 3.0, 2.0 };
			[line setLineDash:dash count:2 phase:0.0];
			line.lineWidth = 1.0;
			[line stroke];
		}
		RptqDocumentSection *guideSec = _dragHoverSection ?: _dragSourceSection ?: _selectedSection;
		if (guideSec) {
			NSRect contentRect = [self sectionContentRectForSection:guideSec];
			for (NSNumber *gy in _activeHorizontalGuides) {
				CGFloat canvasY = contentRect.origin.y + gy.doubleValue;
				NSBezierPath *line = [NSBezierPath bezierPath];
				[line moveToPoint:NSMakePoint(contentRect.origin.x, canvasY + 0.5)];
				[line lineToPoint:NSMakePoint(NSMaxX(contentRect), canvasY + 0.5)];
				CGFloat dash[2] = { 3.0, 2.0 };
				[line setLineDash:dash count:2 phase:0.0];
				line.lineWidth = 1.0;
				[line stroke];
			}
		}
	}

	// Draw marquee selection rectangle.
	if (_dragMode == MADMacCanvasDragModeMarquee && !NSIsEmptyRect(_marqueeRectInCanvas)) {
		[[[NSColor controlAccentColor] colorWithAlphaComponent:0.12] setFill];
		NSRectFillUsingOperation(_marqueeRectInCanvas, NSCompositingOperationSourceOver);
		[[NSColor controlAccentColor] setStroke];
		NSBezierPath *mPath = [NSBezierPath bezierPathWithRect:NSInsetRect(_marqueeRectInCanvas, 0.5, 0.5)];
		mPath.lineWidth = 1.0;
		[mPath stroke];
	}

	// Draw external drag-and-drop insertion indicator.
	if (_hasActiveDropTarget && _dropTargetSection) {
		NSRect contentRect = [self sectionContentRectForSection:_dropTargetSection];
		NSRect previewRect = NSMakeRect(contentRect.origin.x + _dropTargetPointInSection.x,
										contentRect.origin.y + _dropTargetPointInSection.y,
										132.0, 22.0);
		[[[NSColor controlAccentColor] colorWithAlphaComponent:0.18] setFill];
		NSBezierPath *dropBox = [NSBezierPath bezierPathWithRoundedRect:previewRect xRadius:3.0 yRadius:3.0];
		[dropBox fill];
		[[NSColor controlAccentColor] setStroke];
		dropBox.lineWidth = 1.5;
		[dropBox stroke];
	}

	[ctx restoreGraphicsState];
}

- (void)drawTopHorizontalRuler {
	CGFloat paperX = [self paperOriginX];
	CGFloat paperW = [self paperWidth];
	CGFloat leftM = [self leftMargin];
	CGFloat rightM = [self rightMargin];
	NSRect rulerRect = NSMakeRect(paperX, kCanvasOuterMargin, paperW, kRulerTopHeight);

	[[NSColor windowBackgroundColor] setFill];
	NSBezierPath *bg = [NSBezierPath bezierPathWithRoundedRect:rulerRect xRadius:3.0 yRadius:3.0];
	[bg fill];

	[[[NSColor secondaryLabelColor] colorWithAlphaComponent:0.10] setFill];
	if (leftM > 0) {
		NSRectFillUsingOperation(NSMakeRect(paperX, kCanvasOuterMargin, leftM, kRulerTopHeight), NSCompositingOperationSourceOver);
	}
	if (rightM > 0) {
		NSRectFillUsingOperation(NSMakeRect(paperX + paperW - rightM, kCanvasOuterMargin, rightM, kRulerTopHeight), NSCompositingOperationSourceOver);
	}

	[[NSColor separatorColor] setStroke];
	[bg stroke];

	NSDictionary *tickAttrs = @{
		NSFontAttributeName: [NSFont monospacedDigitSystemFontOfSize:8.5 weight:NSFontWeightRegular],
		NSForegroundColorAttributeName: [NSColor secondaryLabelColor]
	};

	CGFloat contentStartX = paperX + leftM;
	CGFloat contentWidth = MAX(0.0, paperW - leftM - rightM);
	for (CGFloat pt = 0.0; pt <= contentWidth + 0.5; pt += 12.0) {
		CGFloat x = contentStartX + pt;
		BOOL isInch = (((int)round(pt)) % 72 == 0);
		BOOL isHalfInch = (((int)round(pt)) % 36 == 0);
		CGFloat tickH = isInch ? 9.0 : (isHalfInch ? 6.0 : 3.5);
		[[NSColor tertiaryLabelColor] setStroke];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x + 0.5, NSMaxY(rulerRect) - tickH)
								  toPoint:NSMakePoint(x + 0.5, NSMaxY(rulerRect))];
		if (isInch) {
			NSString *label = [NSString stringWithFormat:@"%d", (int)round(pt)];
			[label drawAtPoint:NSMakePoint(x + 2.5, rulerRect.origin.y + 1.5) withAttributes:tickAttrs];
		}
	}
}

- (void)drawSectionBand:(RptqDocumentSection *)section {
	NSRect bandRect = [self sectionBandRectForSection:section];
	NSRect contentRect = [self sectionContentRectForSection:section];
	BOOL isSelectedSec = [section isEqual:self.selectedSection];
	BOOL isDropHoverSec = (_hasActiveDropTarget && [section isEqual:_dropTargetSection]) ||
						  (_dragMode == MADMacCanvasDragModeMoveElement && _dragHoverSection && [section isEqual:_dragHoverSection] && ![_dragHoverSection isEqual:_dragSourceSection]);
	NSColor *accentColor = [MADMacDesignerCanvasView accentColorForSection:section];

	NSRect shadowRect = NSOffsetRect(bandRect, 0.0, 1.5);
	[[[NSColor blackColor] colorWithAlphaComponent:0.08] setFill];
	[[NSBezierPath bezierPathWithRoundedRect:shadowRect xRadius:4.0 yRadius:4.0] fill];

	[[NSColor whiteColor] setFill];
	NSBezierPath *bandPath = [NSBezierPath bezierPathWithRoundedRect:bandRect xRadius:4.0 yRadius:4.0];
	[bandPath fill];

	[[[NSColor windowBackgroundColor] colorWithAlphaComponent:0.70] setFill];
	NSRect leftMarginRect = NSMakeRect(bandRect.origin.x, contentRect.origin.y, contentRect.origin.x - bandRect.origin.x, contentRect.size.height);
	NSRect rightMarginRect = NSMakeRect(NSMaxX(contentRect), contentRect.origin.y, NSMaxX(bandRect) - NSMaxX(contentRect), contentRect.size.height);
	NSRectFill(leftMarginRect);
	NSRectFill(rightMarginRect);

	if (_showRulers && section.visibility && leftMarginRect.size.width >= 10.0) {
		[[NSColor quaternaryLabelColor] setStroke];
		for (CGFloat y = 0.0; y <= contentRect.size.height; y += 16.0) {
			CGFloat tickW = (((int)round(y)) % 32 == 0) ? 6.0 : 3.0;
			[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(leftMarginRect) - tickW, contentRect.origin.y + y + 0.5)
									  toPoint:NSMakePoint(NSMaxX(leftMarginRect), contentRect.origin.y + y + 0.5)];
		}
	}

	if (_showGrid && section.visibility && _gridSpacing >= 4.0) {
		[[[NSColor blackColor] colorWithAlphaComponent:0.045] setStroke];
		NSBezierPath *gridPath = [NSBezierPath bezierPath];
		for (CGFloat gx = _gridSpacing; gx < contentRect.size.width; gx += _gridSpacing) {
			[gridPath moveToPoint:NSMakePoint(contentRect.origin.x + gx + 0.5, contentRect.origin.y)];
			[gridPath lineToPoint:NSMakePoint(contentRect.origin.x + gx + 0.5, NSMaxY(contentRect))];
		}
		for (CGFloat gy = _gridSpacing; gy < contentRect.size.height; gy += _gridSpacing) {
			[gridPath moveToPoint:NSMakePoint(contentRect.origin.x, contentRect.origin.y + gy + 0.5)];
			[gridPath lineToPoint:NSMakePoint(NSMaxX(contentRect), contentRect.origin.y + gy + 0.5)];
		}
		gridPath.lineWidth = 0.5;
		[gridPath stroke];
	}

	NSRect headerRect = NSMakeRect(bandRect.origin.x, bandRect.origin.y, bandRect.size.width, kSectionHeaderHeight);
	NSColor *headerFill = isSelectedSec
		? [accentColor colorWithAlphaComponent:0.15]
		: [[NSColor windowBackgroundColor] colorWithAlphaComponent:0.95];
	[headerFill setFill];
	NSRectFillUsingOperation(headerRect, NSCompositingOperationSourceOver);

	[accentColor setFill];
	NSRectFill(NSMakeRect(headerRect.origin.x, headerRect.origin.y, 4.0, headerRect.size.height));

	NSString *badgeText = [MADMacDesignerCanvasView shortBadgeForSection:section];
	NSDictionary *badgeAttrs = @{
		NSFontAttributeName: [NSFont systemFontOfSize:9.5 weight:NSFontWeightBold],
		NSForegroundColorAttributeName: accentColor
	};
	NSSize badgeSize = [badgeText sizeWithAttributes:badgeAttrs];
	NSRect badgeRect = NSMakeRect(headerRect.origin.x + 10.0,
								  headerRect.origin.y + floor((kSectionHeaderHeight - 15.0) * 0.5),
								  badgeSize.width + 10.0,
								  15.0);
	[[accentColor colorWithAlphaComponent:0.14] setFill];
	[[NSBezierPath bezierPathWithRoundedRect:badgeRect xRadius:3.5 yRadius:3.5] fill];
	[badgeText drawAtPoint:NSMakePoint(badgeRect.origin.x + 5.0, badgeRect.origin.y + 1.5) withAttributes:badgeAttrs];

	MADMacDocument *doc = self.document;
	NSString *title = doc ? [doc displayTitleForSection:section] : ([section localizedDisplayName] ?: @"Section");
	if (!section.visibility) {
		title = [title stringByAppendingString:@" (Hidden)"];
	}
	NSDictionary *titleAttrs = @{
		NSFontAttributeName: [NSFont systemFontOfSize:11.0 weight:isSelectedSec ? NSFontWeightSemibold : NSFontWeightMedium],
		NSForegroundColorAttributeName: isSelectedSec ? [NSColor labelColor] : [NSColor secondaryLabelColor]
	};
	[title drawAtPoint:NSMakePoint(NSMaxX(badgeRect) + 8.0, headerRect.origin.y + 4.5) withAttributes:titleAttrs];

	NSUInteger count = [self elementsInSection:section].count;
	NSString *metaText = [NSString stringWithFormat:@"%lu %@ · %.0f pt%@",
						  (unsigned long)count,
						  count == 1 ? @"item" : @"items",
						  contentRect.size.height,
						  [section producesFormFeed] ? @" · Page Break" : @""];
	NSDictionary *metaAttrs = @{
		NSFontAttributeName: [NSFont monospacedDigitSystemFontOfSize:10.0 weight:NSFontWeightRegular],
		NSForegroundColorAttributeName: [NSColor secondaryLabelColor]
	};
	NSSize metaSize = [metaText sizeWithAttributes:metaAttrs];
	[metaText drawAtPoint:NSMakePoint(NSMaxX(headerRect) - metaSize.width - 10.0, headerRect.origin.y + 5.0)
		   withAttributes:metaAttrs];

	[[[NSColor controlAccentColor] colorWithAlphaComponent:0.22] setStroke];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(contentRect.origin.x + 0.5, contentRect.origin.y)
							  toPoint:NSMakePoint(contentRect.origin.x + 0.5, NSMaxY(contentRect))];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(contentRect) - 0.5, contentRect.origin.y)
							  toPoint:NSMakePoint(NSMaxX(contentRect) - 0.5, NSMaxY(contentRect))];

	if (section.visibility) {
		NSArray<RptqDocumentElement *> *elems = [self elementsInSection:section];
		if (elems.count == 0) {
			NSString *hint = @"Drag a query field or toolbar element here";
			NSDictionary *hintAttrs = @{
				NSFontAttributeName: [NSFont systemFontOfSize:10.5 weight:NSFontWeightRegular],
				NSForegroundColorAttributeName: [NSColor placeholderTextColor]
			};
			NSSize hs = [hint sizeWithAttributes:hintAttrs];
			if (contentRect.size.height >= hs.height + 6.0) {
				[hint drawAtPoint:NSMakePoint(contentRect.origin.x + 12.0,
											  contentRect.origin.y + floor((contentRect.size.height - hs.height) * 0.5))
				   withAttributes:hintAttrs];
			}
		} else {
			for (RptqDocumentElement *el in elems) {
				[self drawElement:el inSectionContentRect:contentRect];
			}
		}
	} else {
		[[[NSColor secondaryLabelColor] colorWithAlphaComponent:0.08] setFill];
		NSRectFillUsingOperation(contentRect, NSCompositingOperationSourceOver);
	}

	NSRect resizeRect = NSMakeRect(bandRect.origin.x, NSMaxY(bandRect) - kSectionResizeBarHeight, bandRect.size.width, kSectionResizeBarHeight);
	[[[NSColor windowBackgroundColor] colorWithAlphaComponent:0.9] setFill];
	NSRectFill(resizeRect);
	[[NSColor tertiaryLabelColor] setFill];
	CGFloat midX = NSMidX(resizeRect);
	CGFloat midY = NSMidY(resizeRect) - 1.0;
	for (NSInteger i = -2; i <= 2; i++) {
		NSRectFill(NSMakeRect(midX + i * 5.0 - 1.0, midY, 2.0, 2.0));
	}

	if (isDropHoverSec) {
		[[NSColor controlAccentColor] setStroke];
		bandPath.lineWidth = 2.0;
	} else if (isSelectedSec) {
		[[accentColor colorWithAlphaComponent:0.85] setStroke];
		bandPath.lineWidth = 1.5;
	} else {
		[[NSColor separatorColor] setStroke];
		bandPath.lineWidth = 1.0;
	}
	[bandPath stroke];
}

- (void)drawElement:(RptqDocumentElement *)element inSectionContentRect:(NSRect)contentRect {
	NSRect rel = [self elementRectInSectionContent:element];
	NSRect frame = NSMakeRect(contentRect.origin.x + rel.origin.x,
							  contentRect.origin.y + rel.origin.y,
							  rel.size.width,
							  rel.size.height);

	BOOL isSelected = [_mutableSelectedElements containsObject:element];
	BOOL isCrossSectionDragging = (_dragMode == MADMacCanvasDragModeMoveElement &&
								   isSelected &&
								   _dragHoverSection &&
								   ![_dragHoverSection isEqual:_dragSourceSection]);

	NSColor *bgColor = [element.backgroundColor isKindOfClass:[NSColor class]] ? (NSColor *)element.backgroundColor : nil;
	if (bgColor && bgColor.alphaComponent > 0.01) {
		[bgColor setFill];
		NSRectFillUsingOperation(frame, NSCompositingOperationSourceOver);
	} else {
		NSColor *tint = [NSColor colorWithCalibratedWhite:0.97 alpha:0.92];
		if ([element isKindOfClass:[RptqDocumentElementLabelDataField class]]) {
			tint = [NSColor colorWithCalibratedRed:0.92 green:0.96 blue:1.0 alpha:0.92];
		} else if ([element isKindOfClass:[RptqDocumentElementAggregate class]]) {
			tint = [NSColor colorWithCalibratedRed:0.94 green:0.98 blue:0.93 alpha:0.92];
		} else if ([element isKindOfClass:[RptqDocumentElementBarcode class]]) {
			tint = [NSColor colorWithCalibratedRed:0.98 green:0.96 blue:0.91 alpha:0.92];
		}
		[tint setFill];
		NSRectFillUsingOperation(frame, NSCompositingOperationSourceOver);
	}

	RptqDirectionalAsymmetry *bw = element.border ? element.border.width : nil;
	if (bw && (bw.top > 0 || bw.bottom > 0 || bw.left > 0 || bw.right > 0)) {
		[[NSColor blackColor] setStroke];
		if (bw.top > 0) {
			NSBezierPath *p = [NSBezierPath bezierPath];
			p.lineWidth = bw.top;
			[p moveToPoint:NSMakePoint(NSMinX(frame), NSMinY(frame) + bw.top * 0.5)];
			[p lineToPoint:NSMakePoint(NSMaxX(frame), NSMinY(frame) + bw.top * 0.5)];
			[p stroke];
		}
		if (bw.bottom > 0) {
			NSBezierPath *p = [NSBezierPath bezierPath];
			p.lineWidth = bw.bottom;
			[p moveToPoint:NSMakePoint(NSMinX(frame), NSMaxY(frame) - bw.bottom * 0.5)];
			[p lineToPoint:NSMakePoint(NSMaxX(frame), NSMaxY(frame) - bw.bottom * 0.5)];
			[p stroke];
		}
		if (bw.left > 0) {
			NSBezierPath *p = [NSBezierPath bezierPath];
			p.lineWidth = bw.left;
			[p moveToPoint:NSMakePoint(NSMinX(frame) + bw.left * 0.5, NSMinY(frame))];
			[p lineToPoint:NSMakePoint(NSMinX(frame) + bw.left * 0.5, NSMaxY(frame))];
			[p stroke];
		}
		if (bw.right > 0) {
			NSBezierPath *p = [NSBezierPath bezierPath];
			p.lineWidth = bw.right;
			[p moveToPoint:NSMakePoint(NSMaxX(frame) - bw.right * 0.5, NSMinY(frame))];
			[p lineToPoint:NSMakePoint(NSMaxX(frame) - bw.right * 0.5, NSMaxY(frame))];
			[p stroke];
		}
	} else {
		[[[NSColor grayColor] colorWithAlphaComponent:0.40] setStroke];
		NSBezierPath *outline = [NSBezierPath bezierPathWithRect:NSInsetRect(frame, 0.5, 0.5)];
		outline.lineWidth = 0.75;
		[outline stroke];
	}

	RptqDirectionalAsymmetry *pad = element.padding;
	NSRect innerFrame = NSMakeRect(frame.origin.x + (pad ? pad.left : 4.0),
								   frame.origin.y + (pad ? pad.top : 2.0),
								   MAX(4.0, frame.size.width - (pad ? (pad.left + pad.right) : 8.0)),
								   MAX(4.0, frame.size.height - (pad ? (pad.top + pad.bottom) : 4.0)));

	if ([element isKindOfClass:[RptqDocumentElementImage class]]) {
		RptqDocumentElementImage *imgEl = (RptqDocumentElementImage *)element;
		NSImage *nsImg = [imgEl.image isKindOfClass:[NSImage class]] ? (NSImage *)imgEl.image : nil;
		if (nsImg) {
			[nsImg drawInRect:NSInsetRect(frame, 1.5, 1.5)];
		} else {
			NSDictionary *attrs = @{
				NSFontAttributeName: [NSFont systemFontOfSize:10.0 weight:NSFontWeightMedium],
				NSForegroundColorAttributeName: [NSColor secondaryLabelColor]
			};
			[@"[Image]" drawInRect:innerFrame withAttributes:attrs];
		}
	} else if ([element isKindOfClass:[RptqDocumentElementBarcode class]]) {
		RptqDocumentElementBarcode *bcEl = (RptqDocumentElementBarcode *)element;
		NSString *samplePayload = (bcEl.useStaticInput1 && bcEl.inputStatic1.length > 0)
			? bcEl.inputStatic1
			: (bcEl.referencesField1.databaseSchemaField.name ?: @"123456789012");
		MADBarcode *barcode = [MADBarcode newBarcode:bcEl
											  input1:samplePayload
											  input2:(bcEl.inputStatic2 ?: @"")];
		if (barcode) {
			[barcode drawInRect:NSInsetRect(frame, 2.0, 2.0)];
		} else {
			NSDictionary *txtAttrs = @{
				NSFontAttributeName: [NSFont systemFontOfSize:10.0 weight:NSFontWeightMedium],
				NSForegroundColorAttributeName: [NSColor darkGrayColor]
			};
			[[self displayTitleForElement:element] drawInRect:innerFrame withAttributes:txtAttrs];
		}
	} else if (!(_inlineEditingLabel && [element isEqual:_inlineEditingLabel])) {
		NSString *text = [self displayTitleForElement:element];
		CGFloat fontSize = element.fontsize > 4.0 ? MIN(48.0, (CGFloat)element.fontsize) : 11.0;
		NSString *fontFamily = element.fontname.length > 0 ? element.fontname : @"Helvetica";
		NSFontDescriptor *desc = [NSFontDescriptor newFontDescriptorForFontName:fontFamily
																	   fontSize:fontSize
																		   bold:element.textStyle.bold
																		 italic:element.textStyle.italic];
		NSFont *font = [NSFont fontWithDescriptor:desc size:fontSize] ?: [NSFont systemFontOfSize:fontSize];

		NSColor *fgColor = [element.foregroundColor isKindOfClass:[NSColor class]]
			? (NSColor *)element.foregroundColor
			: [NSColor blackColor];

		NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];
		pStyle.lineBreakMode = NSLineBreakByTruncatingTail;
		if (element.alignment.horizontal == MADHorizontalAlignmentCenter) {
			pStyle.alignment = NSTextAlignmentCenter;
		} else if (element.alignment.horizontal == MADHorizontalAlignmentRight) {
			pStyle.alignment = NSTextAlignmentRight;
		} else {
			pStyle.alignment = NSTextAlignmentLeft;
		}

		NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithDictionary:@{
			NSFontAttributeName: font,
			NSForegroundColorAttributeName: isCrossSectionDragging ? [fgColor colorWithAlphaComponent:0.45] : fgColor,
			NSParagraphStyleAttributeName: pStyle
		}];
		if (element.textStyle.underline) {
			attrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
		}
		if (element.textStyle.strikethrough) {
			attrs[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
		}

		NSSize textSize = [text sizeWithAttributes:attrs];
		CGFloat drawY = innerFrame.origin.y;
		if (element.alignment.vertical == MADVerticalAlignmentCenter) {
			drawY = innerFrame.origin.y + MAX(0.0, floor((innerFrame.size.height - textSize.height) * 0.5));
		} else if (element.alignment.vertical == MADVerticalAlignmentBottom) {
			drawY = MAX(innerFrame.origin.y, NSMaxY(innerFrame) - textSize.height);
		}
		NSRect textDrawRect = NSMakeRect(innerFrame.origin.x, drawY, innerFrame.size.width, MIN(innerFrame.size.height, textSize.height + 4.0));
		[text drawInRect:textDrawRect withAttributes:attrs];

		if (element.numericFormat && element.numericFormat.enabled && frame.size.width > 44.0) {
			NSDictionary *currAttrs = @{
				NSFontAttributeName: [NSFont systemFontOfSize:8.5 weight:NSFontWeightBold],
				NSForegroundColorAttributeName: [NSColor systemGreenColor]
			};
			[@"#" drawAtPoint:NSMakePoint(NSMaxX(frame) - 9.0, NSMinY(frame) + 1.5) withAttributes:currAttrs];
		}
	}

	if (isSelected) {
		[[NSColor controlAccentColor] setStroke];
		NSBezierPath *selPath = [NSBezierPath bezierPathWithRect:frame];
		selPath.lineWidth = 1.5;
		[selPath stroke];

		for (NSInteger h = MADMacResizeHandleTopLeft; h <= MADMacResizeHandleLeft; h++) {
			NSRect hRect = [self handleRectForHandle:(MADMacResizeHandle)h onElementFrame:frame];
			[[NSColor whiteColor] setFill];
			NSRectFill(hRect);
			[[NSColor controlAccentColor] setStroke];
			NSFrameRectWithWidth(hRect, 1.25);
		}
	}
}

- (NSRect)handleRectForHandle:(MADMacResizeHandle)handle onElementFrame:(NSRect)frame {
	CGFloat hs = 6.0;
	CGFloat half = hs * 0.5;
	switch (handle) {
		case MADMacResizeHandleTopLeft:     return NSMakeRect(NSMinX(frame) - half, NSMinY(frame) - half, hs, hs);
		case MADMacResizeHandleTop:         return NSMakeRect(NSMidX(frame) - half, NSMinY(frame) - half, hs, hs);
		case MADMacResizeHandleTopRight:    return NSMakeRect(NSMaxX(frame) - half, NSMinY(frame) - half, hs, hs);
		case MADMacResizeHandleRight:       return NSMakeRect(NSMaxX(frame) - half, NSMidY(frame) - half, hs, hs);
		case MADMacResizeHandleBottomRight: return NSMakeRect(NSMaxX(frame) - half, NSMaxY(frame) - half, hs, hs);
		case MADMacResizeHandleBottom:      return NSMakeRect(NSMidX(frame) - half, NSMaxY(frame) - half, hs, hs);
		case MADMacResizeHandleBottomLeft:  return NSMakeRect(NSMinX(frame) - half, NSMaxY(frame) - half, hs, hs);
		case MADMacResizeHandleLeft:        return NSMakeRect(NSMinX(frame) - half, NSMidY(frame) - half, hs, hs);
		default:                            return NSZeroRect;
	}
}

- (MADMacResizeHandle)hitTestResizeHandleAtCanvasPoint:(NSPoint)pt forElement:(RptqDocumentElement *)element {
	RptqDocumentSection *sec = [self sectionContainingElement:element];
	if (!sec || !sec.visibility) return MADMacResizeHandleNone;
	NSRect contentRect = [self sectionContentRectForSection:sec];
	NSRect rel = [self elementRectInSectionContent:element];
	NSRect frame = NSMakeRect(contentRect.origin.x + rel.origin.x,
							  contentRect.origin.y + rel.origin.y,
							  rel.size.width,
							  rel.size.height);
	for (NSInteger h = MADMacResizeHandleTopLeft; h <= MADMacResizeHandleLeft; h++) {
		NSRect hr = NSInsetRect([self handleRectForHandle:(MADMacResizeHandle)h onElementFrame:frame], -2.5, -2.5);
		if (NSPointInRect(pt, hr)) {
			return (MADMacResizeHandle)h;
		}
	}
	return MADMacResizeHandleNone;
}

#pragma mark - Inline Label Editing

- (void)beginInlineEditingForLabel:(RptqDocumentElementLabel *)label {
	if (!label) return;
	[self commitInlineEditingIfNeeded];
	_inlineEditingLabel = label;
	_inlineEditingOriginalText = [label.text copy] ?: @"";

	NSTextField *editor = [[NSTextField alloc] initWithFrame:NSZeroRect];
	editor.stringValue = _inlineEditingOriginalText;
	editor.font = [NSFont systemFontOfSize:MAX(11.0, label.fontsize * _zoomScale)];
	editor.bezeled = YES;
	editor.bezelStyle = NSTextFieldSquareBezel;
	editor.drawsBackground = YES;
	editor.backgroundColor = [NSColor textBackgroundColor];
	editor.textColor = [NSColor textColor];
	editor.delegate = self;
	editor.target = self;
	editor.action = @selector(inlineEditorDidEndAction:);
	_inlineEditorField = editor;
	[self addSubview:editor];
	[self updateInlineEditorFrameIfNeeded];
	[self.window makeFirstResponder:editor];
	[editor selectText:nil];
	[self setNeedsDisplay:YES];
}

- (void)inlineEditorDidEndAction:(__unused id)sender {
	[self commitInlineEditingIfNeeded];
}

- (void)controlTextDidEndEditing:(__unused NSNotification *)obj {
	[self commitInlineEditingIfNeeded];
}

- (void)commitInlineEditingIfNeeded {
	if (!_inlineEditorField || !_inlineEditingLabel) return;
	RptqDocumentElementLabel *label = _inlineEditingLabel;
	NSString *oldText = _inlineEditingOriginalText ?: @"";
	NSString *newText = _inlineEditorField.stringValue ?: @"";
	[_inlineEditorField removeFromSuperview];
	_inlineEditorField = nil;
	_inlineEditingLabel = nil;
	_inlineEditingOriginalText = nil;

	if (![oldText isEqualToString:newText]) {
		label.text = newText;
		if ([self.delegate respondsToSelector:@selector(designerCanvas:didInlineEditLabel:oldText:newText:)]) {
			[self.delegate designerCanvas:self didInlineEditLabel:label oldText:oldText newText:newText];
		} else if ([self.delegate respondsToSelector:@selector(designerCanvasDidMutateDocument:)]) {
			[self.delegate designerCanvasDidMutateDocument:self];
		}
	}
	[self setNeedsDisplay:YES];
}
#pragma mark - Mouse & Cursor Handling

- (NSPoint)canvasPointFromEvent:(NSEvent *)event {
	NSPoint viewPt = [self convertPoint:event.locationInWindow fromView:nil];
	return NSMakePoint(viewPt.x / _zoomScale, viewPt.y / _zoomScale);
}

- (RptqDocumentSection *)sectionForCanvasPoint:(NSPoint)pt {
	NSArray<RptqDocumentSection *> *sections = [self orderedSections];
	for (RptqDocumentSection *sec in sections) {
		NSRect band = [self sectionBandRectForSection:sec];
		if (NSPointInRect(pt, band)) {
			return sec;
		}
	}
	RptqDocumentSection *nearest = nil;
	CGFloat bestDist = CGFLOAT_MAX;
	for (RptqDocumentSection *sec in sections) {
		if (!sec.visibility) continue;
		NSRect band = [self sectionBandRectForSection:sec];
		CGFloat dist = 0.0;
		if (pt.y < NSMinY(band)) {
			dist = NSMinY(band) - pt.y;
		} else if (pt.y > NSMaxY(band)) {
			dist = pt.y - NSMaxY(band);
		}
		if (dist < bestDist && dist <= kSectionGap + 24.0) {
			bestDist = dist;
			nearest = sec;
		}
	}
	return nearest;
}

- (void)mouseMoved:(NSEvent *)event {
	NSPoint pt = [self canvasPointFromEvent:event];
	NSArray<RptqDocumentSection *> *sections = [self orderedSections];

	for (RptqDocumentSection *sec in sections) {
		NSRect band = [self sectionBandRectForSection:sec];
		NSRect resizeRect = NSMakeRect(band.origin.x, NSMaxY(band) - kSectionResizeBarHeight - 2.0, band.size.width, kSectionResizeBarHeight + 4.0);
		if (NSPointInRect(pt, resizeRect)) {
			[[NSCursor resizeUpDownCursor] set];
			return;
		}
	}

	for (RptqDocumentElement *el in _mutableSelectedElements) {
		MADMacResizeHandle h = [self hitTestResizeHandleAtCanvasPoint:pt forElement:el];
		if (h != MADMacResizeHandleNone) {
			if (h == MADMacResizeHandleLeft || h == MADMacResizeHandleRight) {
				[[NSCursor resizeLeftRightCursor] set];
			} else if (h == MADMacResizeHandleTop || h == MADMacResizeHandleBottom) {
				[[NSCursor resizeUpDownCursor] set];
			} else {
				[[NSCursor crosshairCursor] set];
			}
			return;
		}
	}

	for (RptqDocumentSection *sec in sections) {
		if (!sec.visibility) continue;
		NSRect contentRect = [self sectionContentRectForSection:sec];
		if (!NSPointInRect(pt, contentRect)) continue;
		NSArray<RptqDocumentElement *> *elems = [self elementsInSection:sec];
		for (RptqDocumentElement *el in [elems reverseObjectEnumerator]) {
			NSRect rel = [self elementRectInSectionContent:el];
			NSRect frame = NSMakeRect(contentRect.origin.x + rel.origin.x,
									  contentRect.origin.y + rel.origin.y,
									  rel.size.width,
									  rel.size.height);
			if (NSPointInRect(pt, frame)) {
				[[NSCursor openHandCursor] set];
				return;
			}
		}
	}

	[[NSCursor arrowCursor] set];
}

- (void)rightMouseDown:(NSEvent *)event {
	[self commitInlineEditingIfNeeded];
	NSPoint pt = [self canvasPointFromEvent:event];
	NSArray<RptqDocumentSection *> *sections = [self orderedSections];

	for (RptqDocumentSection *sec in sections) {
		NSRect band = [self sectionBandRectForSection:sec];
		if (!NSPointInRect(pt, band)) continue;
		self.selectedSection = sec;
		NSRect contentRect = [self sectionContentRectForSection:sec];
		if (sec.visibility && NSPointInRect(pt, contentRect)) {
			NSArray<RptqDocumentElement *> *elems = [self elementsInSection:sec];
			for (RptqDocumentElement *el in [elems reverseObjectEnumerator]) {
				NSRect rel = [self elementRectInSectionContent:el];
				NSRect frame = NSMakeRect(contentRect.origin.x + rel.origin.x,
										  contentRect.origin.y + rel.origin.y,
										  rel.size.width,
										  rel.size.height);
				if (NSPointInRect(pt, frame)) {
					if (![_mutableSelectedElements containsObject:el]) {
						[self selectElement:el extendSelection:NO];
					}
					if ([self.delegate respondsToSelector:@selector(designerCanvas:requestContextMenuForElement:inSection:withEvent:)]) {
						[self.delegate designerCanvas:self requestContextMenuForElement:el inSection:sec withEvent:event];
					}
					return;
				}
			}
		}
		if ([self.delegate respondsToSelector:@selector(designerCanvasSelectionDidChange:)]) {
			[self.delegate designerCanvasSelectionDidChange:self];
		}
		if ([self.delegate respondsToSelector:@selector(designerCanvas:requestContextMenuForElement:inSection:withEvent:)]) {
			[self.delegate designerCanvas:self requestContextMenuForElement:nil inSection:sec withEvent:event];
		}
		return;
	}
}

- (void)mouseDown:(NSEvent *)event {
	[self.window makeFirstResponder:self];
	[self commitInlineEditingIfNeeded];

	NSPoint pt = [self canvasPointFromEvent:event];
	BOOL extend = (event.modifierFlags & (NSEventModifierFlagShift | NSEventModifierFlagCommand)) != 0;

	_dragMode = MADMacCanvasDragModeNone;
	_activeResizeHandle = MADMacResizeHandleNone;
	_dragElement = nil;
	_dragSourceSection = nil;
	_dragHoverSection = nil;
	_resizingSection = nil;
	_dragHasMovedSignificantly = NO;
	[_activeVerticalGuides removeAllObjects];
	[_activeHorizontalGuides removeAllObjects];

	NSArray<RptqDocumentSection *> *sections = [self orderedSections];

	for (RptqDocumentSection *sec in sections) {
		NSRect band = [self sectionBandRectForSection:sec];
		NSRect resizeRect = NSMakeRect(band.origin.x, NSMaxY(band) - kSectionResizeBarHeight - 2.0, band.size.width, kSectionResizeBarHeight + 4.0);
		if (NSPointInRect(pt, resizeRect)) {
			self.selectedSection = sec;
			_dragMode = MADMacCanvasDragModeResizeSection;
			_resizingSection = sec;
			_dragStartPointInCanvas = pt;
			_dragInitialSectionHeight = [self contentHeightForSection:sec];
			[self setNeedsDisplay:YES];
			if ([self.delegate respondsToSelector:@selector(designerCanvasSelectionDidChange:)]) {
				[self.delegate designerCanvasSelectionDidChange:self];
			}
			return;
		}
	}

	for (RptqDocumentElement *el in _mutableSelectedElements) {
		MADMacResizeHandle handle = [self hitTestResizeHandleAtCanvasPoint:pt forElement:el];
		if (handle != MADMacResizeHandleNone) {
			RptqDocumentSection *sec = [self sectionContainingElement:el];
			self.selectedSection = sec;
			_dragMode = MADMacCanvasDragModeResizeElement;
			_activeResizeHandle = handle;
			_dragElement = el;
			_dragSourceSection = sec;
			_dragHoverSection = sec;
			_dragStartPointInCanvas = pt;
			_dragInitialElementRect = [self elementRectInSectionContent:el];
			return;
		}
	}

	for (RptqDocumentSection *sec in sections) {
		NSRect band = [self sectionBandRectForSection:sec];
		if (!NSPointInRect(pt, band)) continue;

		self.selectedSection = sec;
		NSRect contentRect = [self sectionContentRectForSection:sec];
		if (sec.visibility) {
			NSArray<RptqDocumentElement *> *elems = [self elementsInSection:sec];
			for (RptqDocumentElement *el in [elems reverseObjectEnumerator]) {
				NSRect rel = [self elementRectInSectionContent:el];
				NSRect frame = NSMakeRect(contentRect.origin.x + rel.origin.x,
										  contentRect.origin.y + rel.origin.y,
										  rel.size.width,
										  rel.size.height);
				if (NSPointInRect(pt, frame)) {
					if (event.clickCount == 2 && [el isKindOfClass:[RptqDocumentElementLabel class]]) {
						[self selectElement:el extendSelection:NO];
						[self beginInlineEditingForLabel:(RptqDocumentElementLabel *)el];
						return;
					}

					if (extend) {
						[self selectElement:el extendSelection:YES];
					} else if (![_mutableSelectedElements containsObject:el]) {
						[self selectElement:el extendSelection:NO];
					} else {
						if ([self.delegate respondsToSelector:@selector(designerCanvasSelectionDidChange:)]) {
							[self.delegate designerCanvasSelectionDidChange:self];
						}
					}

					if ([_mutableSelectedElements containsObject:el]) {
						_dragMode = MADMacCanvasDragModeMoveElement;
						_dragElement = el;
						_dragSourceSection = sec;
						_dragHoverSection = sec;
						_dragStartPointInCanvas = pt;
						_dragInitialElementRect = rel;
						_dragGrabOffsetInElement = NSMakePoint(pt.x - frame.origin.x, pt.y - frame.origin.y);
						_dragLiveOriginInHoverSection = rel.origin;

						_dragInitialOriginsByElement = [NSMapTable strongToStrongObjectsMapTable];
						_dragInitialSectionsByElement = [NSMapTable strongToStrongObjectsMapTable];
						for (RptqDocumentElement *selEl in _mutableSelectedElements) {
							NSRect selRect = [self elementRectInSectionContent:selEl];
							[_dragInitialOriginsByElement setObject:[NSValue valueWithPoint:selRect.origin] forKey:selEl];
							RptqDocumentSection *selSec = [self sectionContainingElement:selEl];
							if (selSec) {
								[_dragInitialSectionsByElement setObject:selSec forKey:selEl];
							}
						}
					}
					return;
				}
			}
		}

		if (!extend) {
			[_mutableSelectedElements removeAllObjects];
		}
		if (sec.visibility && NSPointInRect(pt, contentRect)) {
			_dragMode = MADMacCanvasDragModeMarquee;
			_dragStartPointInCanvas = pt;
			_marqueeRectInCanvas = NSZeroRect;
		}
		[self setNeedsDisplay:YES];
		if ([self.delegate respondsToSelector:@selector(designerCanvasSelectionDidChange:)]) {
			[self.delegate designerCanvasSelectionDidChange:self];
		}
		return;
	}

	[self clearElementSelection];
}

- (NSPoint)applySmartGuidesAndSnapForOrigin:(NSPoint)candidateOrigin
									   size:(NSSize)elementSize
								  inSection:(RptqDocumentSection *)section
								 bypassSnap:(BOOL)bypassSnap {
	[_activeVerticalGuides removeAllObjects];
	[_activeHorizontalGuides removeAllObjects];
	if (bypassSnap) {
		return candidateOrigin;
	}

	CGFloat snappedX = candidateOrigin.x;
	CGFloat snappedY = candidateOrigin.y;
	BOOL matchedXGuide = NO;
	BOOL matchedYGuide = NO;

	CGFloat bestXDiff = kSnapThreshold;
	CGFloat candLeft = candidateOrigin.x;
	CGFloat candMidX = candidateOrigin.x + elementSize.width * 0.5;
	CGFloat candRight = candidateOrigin.x + elementSize.width;
	CGFloat guideXToRecord = 0.0;

	for (RptqDocumentSection *sec in [self orderedSections]) {
		if (!sec.visibility) continue;
		for (RptqDocumentElement *other in [self elementsInSection:sec]) {
			if ([_mutableSelectedElements containsObject:other]) continue;
			NSRect r = [self elementRectInSectionContent:other];
			CGFloat otherEdges[3] = { NSMinX(r), NSMidX(r), NSMaxX(r) };
			CGFloat candEdges[3] = { candLeft, candMidX, candRight };
			CGFloat candOffsets[3] = { 0.0, -elementSize.width * 0.5, -elementSize.width };
			for (int i = 0; i < 3; i++) {
				for (int j = 0; j < 3; j++) {
					CGFloat diff = fabs(candEdges[i] - otherEdges[j]);
					if (diff < bestXDiff) {
						bestXDiff = diff;
						snappedX = otherEdges[j] + candOffsets[i];
						guideXToRecord = otherEdges[j];
						matchedXGuide = YES;
					}
				}
			}
		}
	}
	if (matchedXGuide) {
		[_activeVerticalGuides addObject:@(guideXToRecord)];
	} else if (_snapToGrid && _gridSpacing > 1.0) {
		snappedX = round(snappedX / _gridSpacing) * _gridSpacing;
	}

	if (section) {
		CGFloat bestYDiff = kSnapThreshold;
		CGFloat candTop = candidateOrigin.y;
		CGFloat candMidY = candidateOrigin.y + elementSize.height * 0.5;
		CGFloat candBottom = candidateOrigin.y + elementSize.height;
		CGFloat guideYToRecord = 0.0;

		for (RptqDocumentElement *other in [self elementsInSection:section]) {
			if ([_mutableSelectedElements containsObject:other]) continue;
			NSRect r = [self elementRectInSectionContent:other];
			CGFloat otherEdges[3] = { NSMinY(r), NSMidY(r), NSMaxY(r) };
			CGFloat candEdges[3] = { candTop, candMidY, candBottom };
			CGFloat candOffsets[3] = { 0.0, -elementSize.height * 0.5, -elementSize.height };
			for (int i = 0; i < 3; i++) {
				for (int j = 0; j < 3; j++) {
					CGFloat diff = fabs(candEdges[i] - otherEdges[j]);
					if (diff < bestYDiff) {
						bestYDiff = diff;
						snappedY = otherEdges[j] + candOffsets[i];
						guideYToRecord = otherEdges[j];
						matchedYGuide = YES;
					}
				}
			}
		}
		if (matchedYGuide) {
			[_activeHorizontalGuides addObject:@(guideYToRecord)];
		} else if (_snapToGrid && _gridSpacing > 1.0) {
			snappedY = round(snappedY / _gridSpacing) * _gridSpacing;
		}
	}

	return NSMakePoint(MAX(0.0, snappedX), MAX(0.0, snappedY));
}

- (void)mouseDragged:(NSEvent *)event {
	if (_dragMode == MADMacCanvasDragModeNone) return;
	NSPoint pt = [self canvasPointFromEvent:event];
	CGFloat dx = pt.x - _dragStartPointInCanvas.x;
	CGFloat dy = pt.y - _dragStartPointInCanvas.y;
	if (hypot(dx, dy) >= 1.5) {
		_dragHasMovedSignificantly = YES;
	}
	BOOL bypassSnap = (event.modifierFlags & NSEventModifierFlagOption) != 0;

	if (_dragMode == MADMacCanvasDragModeMoveElement && _dragElement) {
		[[NSCursor closedHandCursor] set];
		RptqDocumentSection *hoverSec = [self sectionForCanvasPoint:pt];
		if (!hoverSec || !hoverSec.visibility) {
			hoverSec = _dragHoverSection ?: _dragSourceSection;
		}
		_dragHoverSection = hoverSec;

		NSRect hoverContent = [self sectionContentRectForSection:hoverSec];
		CGFloat rawX = pt.x - hoverContent.origin.x - _dragGrabOffsetInElement.x;
		CGFloat rawY = pt.y - hoverContent.origin.y - _dragGrabOffsetInElement.y;
		CGFloat maxX = MAX(0.0, hoverContent.size.width - _dragInitialElementRect.size.width);
		rawX = MAX(0.0, MIN(maxX, rawX));
		rawY = MAX(0.0, rawY);

		NSPoint snapped = [self applySmartGuidesAndSnapForOrigin:NSMakePoint(rawX, rawY)
															size:_dragInitialElementRect.size
													   inSection:hoverSec
													  bypassSnap:bypassSnap];
		snapped.x = MAX(0.0, MIN(maxX, snapped.x));
		_dragLiveOriginInHoverSection = snapped;

		if ([hoverSec isEqual:_dragSourceSection]) {
			CGFloat deltaX = snapped.x - _dragInitialElementRect.origin.x;
			CGFloat deltaY = snapped.y - _dragInitialElementRect.origin.y;
			for (RptqDocumentElement *selEl in _mutableSelectedElements) {
				NSValue *initVal = [_dragInitialOriginsByElement objectForKey:selEl];
				NSPoint initPt = initVal ? initVal.pointValue : [self elementRectInSectionContent:selEl].origin;
				NSPoint nextPt = NSMakePoint(MAX(0.0, initPt.x + deltaX), MAX(0.0, initPt.y + deltaY));
				[self setElement:selEl originInSectionContent:nextPt];
			}
			[self recalculateCanvasSize];
		}
		[self setNeedsDisplay:YES];
		if ([self.delegate respondsToSelector:@selector(designerCanvasSelectionDidChange:)]) {
			[self.delegate designerCanvasSelectionDidChange:self];
		}
	} else if (_dragMode == MADMacCanvasDragModeResizeElement && _dragElement) {
		NSRect r = _dragInitialElementRect;
		CGFloat minW = 20.0;
		CGFloat minH = 12.0;
		CGFloat left = NSMinX(r);
		CGFloat right = NSMaxX(r);
		CGFloat top = NSMinY(r);
		CGFloat bottom = NSMaxY(r);

		switch (_activeResizeHandle) {
			case MADMacResizeHandleLeft:
			case MADMacResizeHandleTopLeft:
			case MADMacResizeHandleBottomLeft:
				left = MIN(right - minW, MAX(0.0, left + dx));
				if (_snapToGrid && !bypassSnap && _gridSpacing > 1.0) {
					left = MIN(right - minW, round(left / _gridSpacing) * _gridSpacing);
				}
				break;
			case MADMacResizeHandleRight:
			case MADMacResizeHandleTopRight:
			case MADMacResizeHandleBottomRight:
				right = MAX(left + minW, right + dx);
				if (_snapToGrid && !bypassSnap && _gridSpacing > 1.0) {
					right = MAX(left + minW, round(right / _gridSpacing) * _gridSpacing);
				}
				break;
			default:
				break;
		}

		switch (_activeResizeHandle) {
			case MADMacResizeHandleTop:
			case MADMacResizeHandleTopLeft:
			case MADMacResizeHandleTopRight:
				top = MIN(bottom - minH, MAX(0.0, top + dy));
				if (_snapToGrid && !bypassSnap && _gridSpacing > 1.0) {
					top = MIN(bottom - minH, round(top / _gridSpacing) * _gridSpacing);
				}
				break;
			case MADMacResizeHandleBottom:
			case MADMacResizeHandleBottomLeft:
			case MADMacResizeHandleBottomRight:
				bottom = MAX(top + minH, bottom + dy);
				if (_snapToGrid && !bypassSnap && _gridSpacing > 1.0) {
					bottom = MAX(top + minH, round(bottom / _gridSpacing) * _gridSpacing);
				}
				break;
			default:
				break;
		}

		[self setElement:_dragElement originInSectionContent:NSMakePoint(left, top)];
		[_dragElement setSizeWidth:(float)(right - left) height:(float)(bottom - top)];
		[self recalculateCanvasSize];
		[self setNeedsDisplay:YES];
		if ([self.delegate respondsToSelector:@selector(designerCanvasSelectionDidChange:)]) {
			[self.delegate designerCanvasSelectionDidChange:self];
		}
	} else if (_dragMode == MADMacCanvasDragModeResizeSection && _resizingSection) {
		CGFloat newH = MAX(24.0, MIN(600.0, _dragInitialSectionHeight + dy));
		if (_snapToGrid && !bypassSnap && _gridSpacing > 1.0) {
			newH = round(newH / 4.0) * 4.0;
		}
		[_resizingSection setInterfaceHeight:newH];
		[self recalculateCanvasSize];
		[self setNeedsDisplay:YES];
		if ([self.delegate respondsToSelector:@selector(designerCanvasSelectionDidChange:)]) {
			[self.delegate designerCanvasSelectionDidChange:self];
		}
	} else if (_dragMode == MADMacCanvasDragModeMarquee) {
		CGFloat minX = MIN(_dragStartPointInCanvas.x, pt.x);
		CGFloat minY = MIN(_dragStartPointInCanvas.y, pt.y);
		CGFloat w = fabs(pt.x - _dragStartPointInCanvas.x);
		CGFloat h = fabs(pt.y - _dragStartPointInCanvas.y);
		_marqueeRectInCanvas = NSMakeRect(minX, minY, w, h);

		[_mutableSelectedElements removeAllObjects];
		for (RptqDocumentSection *sec in [self orderedSections]) {
			if (!sec.visibility) continue;
			NSRect contentRect = [self sectionContentRectForSection:sec];
			for (RptqDocumentElement *el in [self elementsInSection:sec]) {
				NSRect rel = [self elementRectInSectionContent:el];
				NSRect frame = NSMakeRect(contentRect.origin.x + rel.origin.x,
										  contentRect.origin.y + rel.origin.y,
										  rel.size.width,
										  rel.size.height);
				if (NSIntersectsRect(_marqueeRectInCanvas, frame)) {
					[_mutableSelectedElements addObject:el];
				}
			}
		}
		[self setNeedsDisplay:YES];
		if ([self.delegate respondsToSelector:@selector(designerCanvasSelectionDidChange:)]) {
			[self.delegate designerCanvasSelectionDidChange:self];
		}
	}
}

- (void)mouseUp:(__unused NSEvent *)event {
	MADMacCanvasDragMode finishedMode = _dragMode;
	RptqDocumentElement *editedElement = _dragElement;
	RptqDocumentSection *sourceSec = _dragSourceSection;
	RptqDocumentSection *hoverSec = _dragHoverSection;
	NSRect oldElementRect = _dragInitialElementRect;
	NSMapTable<RptqDocumentElement *, NSValue *> *initialOrigins = _dragInitialOriginsByElement;
	NSMapTable<RptqDocumentElement *, RptqDocumentSection *> *initialSections = _dragInitialSectionsByElement;
	NSPoint liveHoverOrigin = _dragLiveOriginInHoverSection;
	BOOL movedSignificantly = _dragHasMovedSignificantly;
	RptqDocumentSection *resizedSection = _resizingSection;
	CGFloat oldSectionHeight = _dragInitialSectionHeight;

	_dragMode = MADMacCanvasDragModeNone;
	_activeResizeHandle = MADMacResizeHandleNone;
	_dragElement = nil;
	_dragSourceSection = nil;
	_dragHoverSection = nil;
	_dragInitialOriginsByElement = nil;
	_dragInitialSectionsByElement = nil;
	_resizingSection = nil;
	_marqueeRectInCanvas = NSZeroRect;
	[_activeVerticalGuides removeAllObjects];
	[_activeHorizontalGuides removeAllObjects];

	if (finishedMode == MADMacCanvasDragModeMoveElement && editedElement && movedSignificantly) {
		if (hoverSec && sourceSec && ![hoverSec isEqual:sourceSec]) {
			CGFloat deltaX = liveHoverOrigin.x - oldElementRect.origin.x;
			CGFloat deltaY = liveHoverOrigin.y - oldElementRect.origin.y;
			NSMutableArray<NSDictionary<NSString *, id> *> *moves = [NSMutableArray array];
			NSArray<RptqDocumentElement *> *selectedSnapshot = [_mutableSelectedElements.array copy];
			for (RptqDocumentElement *selEl in selectedSnapshot) {
				NSValue *oldOrigVal = [initialOrigins objectForKey:selEl];
				NSPoint oldOrig = oldOrigVal ? oldOrigVal.pointValue : [self elementRectInSectionContent:selEl].origin;
				RptqDocumentSection *oldSec = [initialSections objectForKey:selEl] ?: sourceSec;
				NSPoint targetOrig = NSMakePoint(MAX(0.0, oldOrig.x + deltaX), MAX(0.0, oldOrig.y + deltaY));
				[self moveElement:selEl toSection:hoverSec atOrigin:targetOrig];
				NSPoint committedOrig = [self elementRectInSectionContent:selEl].origin;
				if (oldSec) {
					[moves addObject:@{
						@"element": selEl,
						@"oldSection": oldSec,
						@"newSection": hoverSec,
						@"oldOrigin": [NSValue valueWithPoint:oldOrig],
						@"newOrigin": [NSValue valueWithPoint:committedOrig]
					}];
				}
			}
			self.selectedSection = hoverSec;
			if ([self.delegate respondsToSelector:@selector(designerCanvas:didMoveElements:)] && moves.count > 0) {
				[self.delegate designerCanvas:self didMoveElements:moves];
			} else if ([self.delegate respondsToSelector:@selector(designerCanvasDidMutateDocument:)]) {
				[self.delegate designerCanvasDidMutateDocument:self];
			}
		} else {
			NSMutableArray<NSDictionary<NSString *, id> *> *changes = [NSMutableArray array];
			for (RptqDocumentElement *selEl in _mutableSelectedElements) {
				NSValue *oldOrigVal = [initialOrigins objectForKey:selEl];
				NSPoint oldOrig = oldOrigVal ? oldOrigVal.pointValue : oldElementRect.origin;
				NSRect newRect = [self elementRectInSectionContent:selEl];
				if (fabs(oldOrig.x - newRect.origin.x) > 0.01 || fabs(oldOrig.y - newRect.origin.y) > 0.01) {
					[changes addObject:@{
						@"element": selEl,
						@"oldOrigin": [NSValue valueWithPoint:oldOrig],
						@"oldSize": [NSValue valueWithSize:newRect.size],
						@"newOrigin": [NSValue valueWithPoint:newRect.origin],
						@"newSize": [NSValue valueWithSize:newRect.size]
					}];
				}
			}
			if (changes.count > 0) {
				if ([self.delegate respondsToSelector:@selector(designerCanvas:didCommitElementGeometry:)]) {
					[self.delegate designerCanvas:self didCommitElementGeometry:changes];
				} else if ([self.delegate respondsToSelector:@selector(designerCanvasDidMutateDocument:)]) {
					[self.delegate designerCanvasDidMutateDocument:self];
				}
			}
		}
	} else if (finishedMode == MADMacCanvasDragModeResizeElement && editedElement && movedSignificantly) {
		NSRect newRect = [self elementRectInSectionContent:editedElement];
		if (!NSEqualRects(oldElementRect, newRect)) {
			NSArray *changes = @[@{
				@"element": editedElement,
				@"oldOrigin": [NSValue valueWithPoint:oldElementRect.origin],
				@"oldSize": [NSValue valueWithSize:oldElementRect.size],
				@"newOrigin": [NSValue valueWithPoint:newRect.origin],
				@"newSize": [NSValue valueWithSize:newRect.size]
			}];
			if ([self.delegate respondsToSelector:@selector(designerCanvas:didCommitElementGeometry:)]) {
				[self.delegate designerCanvas:self didCommitElementGeometry:changes];
			} else if ([self.delegate respondsToSelector:@selector(designerCanvasDidMutateDocument:)]) {
				[self.delegate designerCanvasDidMutateDocument:self];
			}
		}
	} else if (finishedMode == MADMacCanvasDragModeResizeSection && resizedSection) {
		CGFloat newSectionHeight = [self contentHeightForSection:resizedSection];
		if (fabs(oldSectionHeight - newSectionHeight) > 0.01) {
			if ([self.delegate respondsToSelector:@selector(designerCanvas:didCommitSectionResize:oldHeight:newHeight:)]) {
				[self.delegate designerCanvas:self
					   didCommitSectionResize:resizedSection
									oldHeight:oldSectionHeight
									newHeight:newSectionHeight];
			} else if ([self.delegate respondsToSelector:@selector(designerCanvasDidMutateDocument:)]) {
				[self.delegate designerCanvasDidMutateDocument:self];
			}
		}
	}

	[self setNeedsDisplay:YES];
	if ([self.delegate respondsToSelector:@selector(designerCanvasSelectionDidChange:)]) {
		[self.delegate designerCanvasSelectionDidChange:self];
	}
}

#pragma mark - External Drag and Drop (NSDraggingDestination)

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
	return [self draggingUpdated:sender];
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
	NSPasteboard *pb = [sender draggingPasteboard];
	BOOL valid = ([pb availableTypeFromArray:@[MADMacDesignerPasteboardTypeQueryField, MADMacDesignerPasteboardTypeElementKind]] != nil);
	if (!valid) {
		_hasActiveDropTarget = NO;
		[self setNeedsDisplay:YES];
		return NSDragOperationNone;
	}

	NSPoint viewPt = [self convertPoint:[sender draggingLocation] fromView:nil];
	NSPoint canvasPt = NSMakePoint(viewPt.x / _zoomScale, viewPt.y / _zoomScale);
	RptqDocumentSection *sec = [self sectionForCanvasPoint:canvasPt];
	if (!sec) {
		sec = self.selectedSection ?: [self orderedSections].firstObject;
	}
	if (!sec) {
		_hasActiveDropTarget = NO;
		[self setNeedsDisplay:YES];
		return NSDragOperationNone;
	}

	if (!sec.visibility) {
		sec.visibility = YES;
		[self recalculateCanvasSize];
	}
	NSRect contentRect = [self sectionContentRectForSection:sec];
	CGFloat relX = MAX(0.0, MIN(MAX(0.0, contentRect.size.width - 132.0), canvasPt.x - contentRect.origin.x - 20.0));
	CGFloat relY = MAX(0.0, canvasPt.y - contentRect.origin.y - 10.0);
	if (_snapToGrid && _gridSpacing > 1.0) {
		relX = round(relX / _gridSpacing) * _gridSpacing;
		relY = round(relY / _gridSpacing) * _gridSpacing;
	}
	_dropTargetSection = sec;
	_dropTargetPointInSection = NSMakePoint(relX, relY);
	_hasActiveDropTarget = YES;
	[self setNeedsDisplay:YES];
	return NSDragOperationCopy;
}

- (void)draggingExited:(__unused id<NSDraggingInfo>)sender {
	_hasActiveDropTarget = NO;
	_dropTargetSection = nil;
	[self setNeedsDisplay:YES];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
	NSPasteboard *pb = [sender draggingPasteboard];
	RptqDocumentSection *targetSec = _dropTargetSection ?: self.selectedSection ?: [self orderedSections].firstObject;
	NSPoint dropPt = _dropTargetPointInSection;
	_hasActiveDropTarget = NO;
	_dropTargetSection = nil;
	[self setNeedsDisplay:YES];

	if (!targetSec) return NO;

	NSString *fieldPayload = [pb stringForType:MADMacDesignerPasteboardTypeQueryField];
	if (fieldPayload.length > 0) {
		int64_t fieldID = [fieldPayload longLongValue];
		if ([self.delegate respondsToSelector:@selector(designerCanvas:didDropQueryFieldWithIdentifier:inSection:atPoint:)]) {
			[self.delegate designerCanvas:self didDropQueryFieldWithIdentifier:fieldID inSection:targetSec atPoint:dropPt];
			return YES;
		}
	}

	NSString *kindPayload = [pb stringForType:MADMacDesignerPasteboardTypeElementKind];
	if (kindPayload.length > 0) {
		NSInteger kind = [kindPayload integerValue];
		if ([self.delegate respondsToSelector:@selector(designerCanvas:didDropElementKind:inSection:atPoint:)]) {
			[self.delegate designerCanvas:self didDropElementKind:kind inSection:targetSec atPoint:dropPt];
			return YES;
		}
	}
	return NO;
}

#pragma mark - Keyboard Shortcuts

- (void)keyDown:(NSEvent *)event {
	NSString *chars = event.charactersIgnoringModifiers;
	if (chars.length == 0) {
		[super keyDown:event];
		return;
	}
	unichar ch = [chars characterAtIndex:0];
	BOOL cmd = (event.modifierFlags & NSEventModifierFlagCommand) != 0;

	if (cmd && (ch == 'a' || ch == 'A')) {
		[self selectAllElementsInSelectedSection];
		return;
	}
	if (cmd && (ch == 'd' || ch == 'D')) {
		if (_mutableSelectedElements.count > 0 &&
			[self.delegate respondsToSelector:@selector(designerCanvasRequestDuplicateSelection:)]) {
			[self.delegate designerCanvasRequestDuplicateSelection:self];
			return;
		}
	}

	if (ch == NSDeleteCharacter || ch == NSBackspaceCharacter || ch == NSDeleteFunctionKey) {
		if (_mutableSelectedElements.count > 0 &&
			[self.delegate respondsToSelector:@selector(designerCanvasRequestDeleteSelection:)]) {
			[self.delegate designerCanvasRequestDeleteSelection:self];
			return;
		}
	}

	if ((ch == NSCarriageReturnCharacter || ch == NSEnterCharacter) &&
		_mutableSelectedElements.count == 1 &&
		[self.primarySelectedElement isKindOfClass:[RptqDocumentElementLabel class]]) {
		[self beginInlineEditingForLabel:(RptqDocumentElementLabel *)self.primarySelectedElement];
		return;
	}

	CGFloat step = (event.modifierFlags & NSEventModifierFlagShift) ? 10.0 : 1.0;
	CGFloat dx = 0.0, dy = 0.0;
	if (ch == NSLeftArrowFunctionKey) dx = -step;
	else if (ch == NSRightArrowFunctionKey) dx = step;
	else if (ch == NSUpArrowFunctionKey) dy = -step;
	else if (ch == NSDownArrowFunctionKey) dy = step;

	if ((dx != 0.0 || dy != 0.0) && _mutableSelectedElements.count > 0) {
		NSMutableArray<NSDictionary<NSString *, id> *> *changes = [NSMutableArray array];
		for (RptqDocumentElement *el in _mutableSelectedElements) {
			NSRect oldRect = [self elementRectInSectionContent:el];
			NSPoint newOrigin = NSMakePoint(MAX(0.0, oldRect.origin.x + dx), MAX(0.0, oldRect.origin.y + dy));
			[self setElement:el originInSectionContent:newOrigin];
			NSRect newRect = [self elementRectInSectionContent:el];
			[changes addObject:@{
				@"element": el,
				@"oldOrigin": [NSValue valueWithPoint:oldRect.origin],
				@"oldSize": [NSValue valueWithSize:oldRect.size],
				@"newOrigin": [NSValue valueWithPoint:newRect.origin],
				@"newSize": [NSValue valueWithSize:newRect.size]
			}];
		}
		[self recalculateCanvasSize];
		[self setNeedsDisplay:YES];
		if ([self.delegate respondsToSelector:@selector(designerCanvas:didCommitElementGeometry:)]) {
			[self.delegate designerCanvas:self didCommitElementGeometry:changes];
		}
		if ([self.delegate respondsToSelector:@selector(designerCanvasSelectionDidChange:)]) {
			[self.delegate designerCanvasSelectionDidChange:self];
		}
		return;
	}

	[super keyDown:event];
}

@end

#pragma mark - MADMacDesignerMinimapView

@implementation MADMacDesignerMinimapView

- (BOOL)isFlipped {
	return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
	[[NSColor controlBackgroundColor] setFill];
	NSRectFill(dirtyRect);

	MADMacDesignerCanvasView *canvas = self.canvasView;
	if (!canvas) return;
	NSArray<RptqDocumentSection *> *sections = [canvas orderedSections];
	if (sections.count == 0) return;

	CGFloat canvasUnscaledW = MAX(200.0, canvas.bounds.size.width / MAX(0.1, canvas.zoomScale));
	CGFloat canvasUnscaledH = MAX(200.0, canvas.bounds.size.height / MAX(0.1, canvas.zoomScale));

	NSRect insetBounds = NSInsetRect(self.bounds, 6.0, 6.0);
	CGFloat scaleX = insetBounds.size.width / canvasUnscaledW;
	CGFloat scaleY = insetBounds.size.height / canvasUnscaledH;
	CGFloat scale = MIN(scaleX, scaleY);
	CGFloat offsetX = insetBounds.origin.x + floor((insetBounds.size.width - canvasUnscaledW * scale) * 0.5);
	CGFloat offsetY = insetBounds.origin.y + floor((insetBounds.size.height - canvasUnscaledH * scale) * 0.5);

	for (RptqDocumentSection *sec in sections) {
		NSRect band = [canvas sectionBandRectForSection:sec];
		if (NSIsEmptyRect(band)) continue;
		NSRect miniBand = NSMakeRect(offsetX + band.origin.x * scale,
									 offsetY + band.origin.y * scale,
									 band.size.width * scale,
									 MAX(4.0, band.size.height * scale));
		NSColor *accent = [MADMacDesignerCanvasView accentColorForSection:sec];
		BOOL isSelSec = [sec isEqual:canvas.selectedSection];

		[[sec.visibility ? [NSColor whiteColor] : [[NSColor secondaryLabelColor] colorWithAlphaComponent:0.15] colorWithAlphaComponent:0.95] setFill];
		NSRectFill(miniBand);

		[accent setFill];
		NSRectFill(NSMakeRect(miniBand.origin.x, miniBand.origin.y, 3.0, miniBand.size.height));

		if (sec.visibility) {
			NSRect contentRect = [canvas sectionContentRectForSection:sec];
			for (RptqDocumentElement *el in [canvas elementsInSection:sec]) {
				NSRect rel = [canvas elementRectInSectionContent:el];
				NSRect elCanvas = NSMakeRect(contentRect.origin.x + rel.origin.x,
											 contentRect.origin.y + rel.origin.y,
											 rel.size.width,
											 rel.size.height);
				NSRect miniEl = NSMakeRect(offsetX + elCanvas.origin.x * scale,
										   offsetY + elCanvas.origin.y * scale,
										   MAX(2.5, elCanvas.size.width * scale),
										   MAX(2.0, elCanvas.size.height * scale));
				BOOL isSelEl = [canvas.selectedElements containsObject:el];
				[(isSelEl ? [NSColor controlAccentColor] : [accent colorWithAlphaComponent:0.55]) setFill];
				NSRectFill(miniEl);
			}
		}

		[(isSelSec ? accent : [NSColor separatorColor]) setStroke];
		NSFrameRectWithWidth(miniBand, isSelSec ? 1.25 : 0.6);
	}

	NSScrollView *scroll = canvas.enclosingScrollView;
	if (scroll) {
		NSRect vis = scroll.documentVisibleRect;
		CGFloat z = MAX(0.1, canvas.zoomScale);
		NSRect miniVis = NSMakeRect(offsetX + (vis.origin.x / z) * scale,
									offsetY + (vis.origin.y / z) * scale,
									(vis.size.width / z) * scale,
									(vis.size.height / z) * scale);
		miniVis = NSIntersectionRect(miniVis, insetBounds);
		if (!NSIsEmptyRect(miniVis)) {
			[[[NSColor controlAccentColor] colorWithAlphaComponent:0.10] setFill];
			NSRectFillUsingOperation(miniVis, NSCompositingOperationSourceOver);
			[[[NSColor controlAccentColor] colorWithAlphaComponent:0.75] setStroke];
			NSFrameRectWithWidth(miniVis, 1.0);
		}
	}

	[[NSColor separatorColor] setStroke];
	NSFrameRectWithWidth(self.bounds, 0.5);
}

- (void)navigateToMinimapEvent:(NSEvent *)event {
	MADMacDesignerCanvasView *canvas = self.canvasView;
	if (!canvas) return;
	NSPoint pt = [self convertPoint:event.locationInWindow fromView:nil];

	CGFloat canvasUnscaledW = MAX(200.0, canvas.bounds.size.width / MAX(0.1, canvas.zoomScale));
	CGFloat canvasUnscaledH = MAX(200.0, canvas.bounds.size.height / MAX(0.1, canvas.zoomScale));
	NSRect insetBounds = NSInsetRect(self.bounds, 6.0, 6.0);
	CGFloat scale = MIN(insetBounds.size.width / canvasUnscaledW, insetBounds.size.height / canvasUnscaledH);
	if (scale <= 0.0001) return;
	CGFloat offsetX = insetBounds.origin.x + floor((insetBounds.size.width - canvasUnscaledW * scale) * 0.5);
	CGFloat offsetY = insetBounds.origin.y + floor((insetBounds.size.height - canvasUnscaledH * scale) * 0.5);

	NSPoint canvasPt = NSMakePoint((pt.x - offsetX) / scale, (pt.y - offsetY) / scale);
	for (RptqDocumentSection *sec in [canvas orderedSections]) {
		NSRect band = [canvas sectionBandRectForSection:sec];
		if (NSPointInRect(canvasPt, band)) {
			canvas.selectedSection = sec;
			[canvas scrollToSection:sec];
			[canvas setNeedsDisplay:YES];
			if ([canvas.delegate respondsToSelector:@selector(designerCanvasSelectionDidChange:)]) {
				[canvas.delegate designerCanvasSelectionDidChange:canvas];
			}
			[self setNeedsDisplay:YES];
			return;
		}
	}
}

- (void)mouseDown:(NSEvent *)event {
	[self navigateToMinimapEvent:event];
}

- (void)mouseDragged:(NSEvent *)event {
	[self navigateToMinimapEvent:event];
}

@end
