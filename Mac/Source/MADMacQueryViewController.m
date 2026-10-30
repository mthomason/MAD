//
//  MADMacQueryViewController.m
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMacQueryViewController.h"
#import "MADMacDocument.h"

#import <MAD/MAD.h>
#import "MADSQLQueryCompiler.h"
#import "MADSQLStatementResolver.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADDataStructures/MTGraph.h>
#import <MADDataStructures/MTVertex.h>
#import <MADDataStructures/MTLinkedList.h>
#import <MADDataStructures/MTPair.h>
#import <QuartzCore/QuartzCore.h>

static const CGFloat kTopBarHeight = 38.0;
static const CGFloat kDefaultSidebarWidth = 200.0;
static const CGFloat kMinSidebarWidth = 150.0;
static const CGFloat kMaxSidebarWidth = 420.0;

static const CGFloat kDefaultCardWidth = 188.0;
static const CGFloat kDefaultCardHeight = 208.0;
static const CGFloat kMinCardWidth = 148.0;
static const CGFloat kMinCardHeight = 112.0;
static const CGFloat kCardTitleBarHeight = 28.0;
static const CGFloat kCardFieldRowHeight = 20.0;

@class MADMacQueryCanvasView;
@class MADMacQueryTableCardView;
@class MADMacQueryLinksOverlayView;

#pragma mark - Link Geometry Snapshot

@interface MADMacQueryLinkGeometry : NSObject
@property (nonatomic, strong) RptqQueryLinks *link;
@property (nonatomic, assign) NSPoint origin;
@property (nonatomic, assign) NSPoint destination;
@property (nonatomic, assign) NSPoint control1;
@property (nonatomic, assign) NSPoint control2;
@property (nonatomic, assign) NSPoint midpoint;
@property (nonatomic, assign) NSRect badgeRect;
@property (nonatomic, assign) BOOL leftIsInitial;
@end

@implementation MADMacQueryLinkGeometry
@end

#pragma mark - Field Table View Inside Floating Card

@interface MADMacQueryFieldTableView : NSTableView
@property (nonatomic, weak, nullable) MADMacQueryTableCardView *parentCard;
@end

#pragma mark - Floating Table Card View (iPad MADQueryTableViewController + MTTitleView Equivalent)

@interface MADMacQueryTableCardView : NSView <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, weak, nullable) MADMacQueryViewController *controller;
@property (nonatomic, weak, nullable) MADMacQueryCanvasView *canvasView;
@property (nonatomic, strong) RptqQueryTable *queryTable;
@property (nonatomic, copy) NSArray<RptqQueryField *> *orderedFields;
@property (nonatomic, assign) BOOL isRootTable;
@property (nonatomic, assign) NSInteger highlightedTargetRow;

@property (nonatomic, strong, readonly) NSScrollView *scrollView;
@property (nonatomic, strong, readonly) MADMacQueryFieldTableView *tableView;

- (instancetype)initWithFrame:(NSRect)frame
				   queryTable:(RptqQueryTable *)queryTable
				   controller:(MADMacQueryViewController *)controller
				   canvasView:(MADMacQueryCanvasView *)canvasView;
- (void)reloadFields;
- (NSRect)rectForQueryField:(RptqQueryField *)field inCanvas:(NSView *)canvasView;
- (nullable RptqQueryField *)queryFieldAtCanvasPoint:(NSPoint)canvasPoint rowOut:(nullable NSInteger *)rowOut;

@end

#pragma mark - Links Overlay View (iPad MADConnectorView Equivalent)

@interface MADMacQueryLinksOverlayView : NSView
@property (nonatomic, weak, nullable) MADMacQueryCanvasView *canvasView;
@end

#pragma mark - Visual Query Canvas View

@interface MADMacQueryCanvasView : NSView

@property (nonatomic, weak, nullable) MADMacQueryViewController *controller;
@property (nonatomic, strong, readonly) MADMacQueryLinksOverlayView *linksOverlayView;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, MADMacQueryTableCardView *> *cardsByTableID;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, NSValue *> *cachedFramesByTableID;

@property (nonatomic, copy) NSArray<RptqQueryTable *> *queryTables;
@property (nonatomic, copy) NSArray<RptqQueryLinks *> *queryLinks;
@property (nonatomic, assign) int64_t selectedLinkID;

// Interactive field-to-field drag state
@property (nonatomic, strong, nullable) MADMacQueryTableCardView *dragSourceCard;
@property (nonatomic, strong, nullable) RptqQueryField *dragSourceField;
@property (nonatomic, strong, nullable) MADMacQueryTableCardView *dragTargetCard;
@property (nonatomic, strong, nullable) RptqQueryField *dragTargetField;
@property (nonatomic, assign) NSPoint dragCurrentCanvasPoint;
@property (nonatomic, assign) BOOL isDraggingConnection;

- (void)rebuildCanvasWithTables:(NSArray<RptqQueryTable *> *)tables
						  links:(NSArray<RptqQueryLinks *> *)links
					rootTableID:(NSSet<NSNumber *> *)rootTableIDs;
- (void)autoArrangeCardsWithTopologicalOrder:(NSArray<NSNumber *> *)orderedTableIDs
								rootTableIDs:(NSSet<NSNumber *> *)rootTableIDs;
- (void)selectCardBringToFront:(MADMacQueryTableCardView *)card;
- (void)cardDidMoveOrScroll:(MADMacQueryTableCardView *)card;
- (void)ensureCanvasSizeFitsCards;

- (NSArray<MADMacQueryLinkGeometry *> *)computedLinkGeometries;
- (nullable MADMacQueryLinkGeometry *)linkGeometryAtCanvasPoint:(NSPoint)point;

- (void)beginFieldConnectionDragFromCard:(MADMacQueryTableCardView *)card field:(RptqQueryField *)field;
- (void)updateFieldConnectionDragToPoint:(NSPoint)canvasPoint;
- (void)finishFieldConnectionDragAtPoint:(NSPoint)canvasPoint;

@end

@interface MADMacQueryViewController (InternalCanvasSupport)
- (BOOL)isQueryFieldLinked:(RptqQueryField *)field;
- (BOOL)isQueryFieldGrouped:(RptqQueryField *)field;
- (BOOL)isQueryFieldFiltered:(RptqQueryField *)field;
- (void)dismissActiveLinkPopover;
- (NSMenu *)contextMenuForQueryLink:(RptqQueryLinks *)link;
- (NSMenu *)contextMenuForQueryField:(RptqQueryField *)field inCard:(MADMacQueryTableCardView *)card;
@end

#pragma mark - MADMacQueryFieldTableView Implementation

@implementation MADMacQueryFieldTableView

- (BOOL)acceptsFirstMouse:(nullable NSEvent *) __unused event {
	return YES;
}

- (void)mouseDown:(NSEvent *)event {
	MADMacQueryTableCardView *card = self.parentCard;
	if (card == nil) {
		[super mouseDown:event];
		return;
	}
	[card.canvasView selectCardBringToFront:card];

	NSPoint localPt = [self convertPoint:event.locationInWindow fromView:nil];
	NSInteger clickedRow = [self rowAtPoint:localPt];
	if (clickedRow < 0 || (NSUInteger)clickedRow >= card.orderedFields.count) {
		[super mouseDown:event];
		return;
	}

	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:(NSUInteger)clickedRow] byExtendingSelection:NO];
	RptqQueryField *sourceField = card.orderedFields[(NSUInteger)clickedRow];

	NSPoint startWinPt = event.locationInWindow;
	BOOL didDrag = NO;

	while (YES) {
		NSEvent *next = [self.window nextEventMatchingMask:(NSEventMaskLeftMouseDragged | NSEventMaskLeftMouseUp)
												 untilDate:[NSDate distantFuture]
													inMode:NSEventTrackingRunLoopMode
												   dequeue:YES];
		if (next == nil) break;
		NSPoint curWinPt = next.locationInWindow;
		if (next.type == NSEventTypeLeftMouseDragged) {
			if (!didDrag && hypot(curWinPt.x - startWinPt.x, curWinPt.y - startWinPt.y) > 3.0) {
				didDrag = YES;
				[card.canvasView beginFieldConnectionDragFromCard:card field:sourceField];
			}
			if (didDrag) {
				NSPoint canvasPt = [card.canvasView convertPoint:curWinPt fromView:nil];
				[card.canvasView updateFieldConnectionDragToPoint:canvasPt];
			}
		} else if (next.type == NSEventTypeLeftMouseUp) {
			if (didDrag) {
				NSPoint canvasPt = [card.canvasView convertPoint:curWinPt fromView:nil];
				[card.canvasView finishFieldConnectionDragAtPoint:canvasPt];
			}
			break;
		}
	}
}

- (nullable NSMenu *)menuForEvent:(NSEvent *)event {
	MADMacQueryTableCardView *card = self.parentCard;
	if (card == nil) return nil;
	NSPoint localPt = [self convertPoint:event.locationInWindow fromView:nil];
	NSInteger row = [self rowAtPoint:localPt];
	if (row < 0 || (NSUInteger)row >= card.orderedFields.count) return nil;

	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:(NSUInteger)row] byExtendingSelection:NO];
	RptqQueryField *field = card.orderedFields[(NSUInteger)row];
	return [card.controller contextMenuForQueryField:field inCard:card];
}

@end

#pragma mark - MADMacQueryTableCardView Implementation

@implementation MADMacQueryTableCardView {
	NSButton *_removeButton;
}

- (BOOL)isFlipped {
	return YES;
}

- (instancetype)initWithFrame:(NSRect)frame
				   queryTable:(RptqQueryTable *)queryTable
				   controller:(MADMacQueryViewController *)controller
				   canvasView:(MADMacQueryCanvasView *)canvasView {
	if (self = [super initWithFrame:frame]) {
		_queryTable = queryTable;
		_controller = controller;
		_canvasView = canvasView;
		_isRootTable = YES;
		_highlightedTargetRow = -1;
		_orderedFields = @[];

		self.wantsLayer = YES;
		self.layer.cornerRadius = 10.0;
		self.layer.masksToBounds = NO;

		NSShadow *shadow = [[NSShadow alloc] init];
		shadow.shadowColor = [[NSColor blackColor] colorWithAlphaComponent:0.28];
		shadow.shadowOffset = NSMakeSize(0.0, -3.0);
		shadow.shadowBlurRadius = 8.0;
		self.shadow = shadow;

		_removeButton = [[NSButton alloc] initWithFrame:NSMakeRect(frame.size.width - 24.0, 4.0, 20.0, 20.0)];
		_removeButton.bordered = NO;
		_removeButton.title = @"×";
		_removeButton.font = [NSFont boldSystemFontOfSize:14.0];
		_removeButton.contentTintColor = [NSColor whiteColor];
		_removeButton.autoresizingMask = NSViewMinXMargin | NSViewMaxYMargin;
		_removeButton.target = self;
		_removeButton.action = @selector(handleRemoveTableButton:);
		_removeButton.toolTip = @"Remove table from query";
		[self addSubview:_removeButton];

		NSRect scrollFrame = NSMakeRect(1.0, kCardTitleBarHeight, frame.size.width - 2.0, frame.size.height - kCardTitleBarHeight - 8.0);
		_scrollView = [[NSScrollView alloc] initWithFrame:scrollFrame];
		_scrollView.hasVerticalScroller = YES;
		_scrollView.hasHorizontalScroller = NO;
		_scrollView.autohidesScrollers = YES;
		_scrollView.borderType = NSNoBorder;
		_scrollView.drawsBackground = YES;
		_scrollView.backgroundColor = [NSColor controlBackgroundColor];
		_scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
		_scrollView.contentView.postsBoundsChangedNotifications = YES;

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleScrollViewBoundsChanged:)
													 name:NSViewBoundsDidChangeNotification
												   object:_scrollView.contentView];

		_tableView = [[MADMacQueryFieldTableView alloc] initWithFrame:_scrollView.bounds];
		_tableView.parentCard = self;
		_tableView.headerView = nil;
		_tableView.rowHeight = kCardFieldRowHeight;
		_tableView.intercellSpacing = NSMakeSize(0.0, 1.0);
		_tableView.usesAlternatingRowBackgroundColors = NO;
		_tableView.backgroundColor = [NSColor controlBackgroundColor];
		_tableView.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;
		_tableView.delegate = self;
		_tableView.dataSource = self;

		NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:@"field"];
		col.width = scrollFrame.size.width;
		col.minWidth = 80.0;
		col.resizingMask = NSTableColumnAutoresizingMask;
		[_tableView addTableColumn:col];

		_scrollView.documentView = _tableView;
		[self addSubview:_scrollView];

		[self reloadFields];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setIsRootTable:(BOOL)isRootTable {
	if (_isRootTable != isRootTable) {
		_isRootTable = isRootTable;
		_removeButton.contentTintColor = isRootTable ? [NSColor whiteColor] : [MADColorEverydayApps newColorBlue];
		[self setNeedsDisplay:YES];
	}
}

- (void)setHighlightedTargetRow:(NSInteger)highlightedTargetRow {
	if (_highlightedTargetRow != highlightedTargetRow) {
		_highlightedTargetRow = highlightedTargetRow;
		[_tableView reloadData];
	}
}

- (void)reloadFields {
	// Order fields matching schema table's ordered hasFields, just like MADQueryTableViewController on iPad
	NSOrderedSet<RptqDatabaseSchemaField *> *schemaFields = _queryTable.databaseSchemaTable.hasFields;
	NSSet<RptqQueryField *> *qFields = _queryTable.hasQueryFields;

	NSMutableDictionary<NSNumber *, RptqQueryField *> *bySchemaID = [NSMutableDictionary dictionaryWithCapacity:qFields.count];
	for (RptqQueryField *qf in qFields) {
		if (qf.databaseSchemaField != nil) {
			bySchemaID[@(qf.databaseSchemaField.identifier)] = qf;
		}
	}

	NSMutableArray<RptqQueryField *> *ordered = [NSMutableArray arrayWithCapacity:qFields.count];
	for (RptqDatabaseSchemaField *sf in schemaFields) {
		RptqQueryField *qf = bySchemaID[@(sf.identifier)];
		if (qf != nil) {
			[ordered addObject:qf];
			[bySchemaID removeObjectForKey:@(sf.identifier)];
		}
	}
	if (bySchemaID.count > 0) {
		NSSortDescriptor *byName = [NSSortDescriptor sortDescriptorWithKey:@"databaseSchemaField.name"
																 ascending:YES
																  selector:@selector(localizedCaseInsensitiveCompare:)];
		[ordered addObjectsFromArray:[bySchemaID.allValues sortedArrayUsingDescriptors:@[byName]]];
	}
	_orderedFields = [ordered copy];
	[_tableView reloadData];
}

- (void)handleScrollViewBoundsChanged:(NSNotification *) __unused note {
	[_canvasView cardDidMoveOrScroll:self];
}

- (void)handleRemoveTableButton:(id) __unused sender {
	[_controller removeQueryTable:_queryTable];
}

- (void)drawRect:(NSRect) __unused dirtyRect {
	NSRect b = self.bounds;
	NSBezierPath *cardPath = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(b, 0.5, 0.5) xRadius:10.0 yRadius:10.0];
	[[NSColor controlBackgroundColor] setFill];
	[cardPath fill];

	// Title bar (matches MTTitleView / MADTitleViewQueryTable on iPad)
	NSRect titleRect = NSMakeRect(0.5, 0.5, b.size.width - 1.0, kCardTitleBarHeight);
	[NSGraphicsContext saveGraphicsState];
	[cardPath addClip];

	NSColor *madBlue = [MADColorEverydayApps newColorBlue] ?: [NSColor controlAccentColor];
	if (_isRootTable) {
		[madBlue setFill];
		NSRectFill(titleRect);
	} else {
		[[[NSColor windowBackgroundColor] blendedColorWithFraction:0.15 ofColor:madBlue] setFill];
		NSRectFill(titleRect);
	}

	// Bottom border of title bar (matches MTTitleView.m:71-79)
	[madBlue setStroke];
	NSBezierPath *titleLine = [NSBezierPath bezierPath];
	[titleLine moveToPoint:NSMakePoint(0.0, kCardTitleBarHeight)];
	[titleLine lineToPoint:NSMakePoint(b.size.width, kCardTitleBarHeight)];
	titleLine.lineWidth = 1.0;
	[titleLine stroke];

	// Title text (alias)
	NSString *title = _queryTable.alias.length > 0 ? _queryTable.alias : (_queryTable.databaseSchemaTable.name ?: @"Table");
	NSFont *titleFont = _isRootTable
		? [NSFont monospacedDigitSystemFontOfSize:12.0 weight:NSFontWeightSemibold]
		: [NSFont monospacedDigitSystemFontOfSize:11.5 weight:NSFontWeightMedium];
	NSColor *titleColor = _isRootTable ? [NSColor whiteColor] : madBlue;
	NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];
	pStyle.alignment = NSTextAlignmentCenter;
	pStyle.lineBreakMode = NSLineBreakByTruncatingTail;
	NSDictionary *attrs = @{
		NSFontAttributeName: titleFont,
		NSForegroundColorAttributeName: titleColor,
		NSParagraphStyleAttributeName: pStyle,
	};
	NSRect textRect = NSMakeRect(22.0, 5.0, MAX(20.0, b.size.width - 44.0), kCardTitleBarHeight - 6.0);
	[title drawInRect:textRect withAttributes:attrs];

	[NSGraphicsContext restoreGraphicsState];

	// Subtle card border
	[[NSColor separatorColor] setStroke];
	cardPath.lineWidth = 1.0;
	[cardPath stroke];

	// Resize grip at bottom-right corner
	[[NSColor tertiaryLabelColor] setStroke];
	NSBezierPath *grip = [NSBezierPath bezierPath];
	[grip moveToPoint:NSMakePoint(NSMaxX(b) - 10.0, NSMaxY(b) - 3.0)];
	[grip lineToPoint:NSMakePoint(NSMaxX(b) - 3.0, NSMaxY(b) - 10.0)];
	[grip moveToPoint:NSMakePoint(NSMaxX(b) - 6.0, NSMaxY(b) - 3.0)];
	[grip lineToPoint:NSMakePoint(NSMaxX(b) - 3.0, NSMaxY(b) - 6.0)];
	grip.lineWidth = 1.0;
	[grip stroke];
}

- (void)mouseDown:(NSEvent *)event {
	[_canvasView selectCardBringToFront:self];
	NSPoint localStart = [self convertPoint:event.locationInWindow fromView:nil];
	BOOL resizing = (localStart.x >= NSWidth(self.bounds) - 14.0 && localStart.y >= NSHeight(self.bounds) - 14.0);
	BOOL draggingTitle = (localStart.y <= kCardTitleBarHeight) && !resizing;
	if (!resizing && !draggingTitle) {
		[super mouseDown:event];
		return;
	}

	NSPoint startCanvasPt = [_canvasView convertPoint:event.locationInWindow fromView:nil];
	NSRect startFrame = self.frame;

	while (YES) {
		NSEvent *next = [self.window nextEventMatchingMask:(NSEventMaskLeftMouseDragged | NSEventMaskLeftMouseUp)
												 untilDate:[NSDate distantFuture]
													inMode:NSEventTrackingRunLoopMode
												   dequeue:YES];
		if (next == nil) break;
		if (next.type == NSEventTypeLeftMouseDragged) {
			NSPoint curCanvasPt = [_canvasView convertPoint:next.locationInWindow fromView:nil];
			CGFloat dx = curCanvasPt.x - startCanvasPt.x;
			CGFloat dy = curCanvasPt.y - startCanvasPt.y;
			if (resizing) {
				CGFloat newW = MAX(kMinCardWidth, startFrame.size.width + dx);
				CGFloat newH = MAX(kMinCardHeight, startFrame.size.height + dy);
				self.frame = NSMakeRect(startFrame.origin.x, startFrame.origin.y, newW, newH);
			} else {
				CGFloat newX = MAX(12.0, startFrame.origin.x + dx);
				CGFloat newY = MAX(12.0, startFrame.origin.y + dy);
				self.frame = NSMakeRect(newX, newY, startFrame.size.width, startFrame.size.height);
			}
			_canvasView.cachedFramesByTableID[@(_queryTable.identifier)] = [NSValue valueWithRect:self.frame];
			[_canvasView cardDidMoveOrScroll:self];
		} else if (next.type == NSEventTypeLeftMouseUp) {
			[_canvasView ensureCanvasSizeFitsCards];
			break;
		}
	}
}

- (NSRect)rectForQueryField:(RptqQueryField *)field inCanvas:(NSView *)canvasView {
	NSUInteger idx = [_orderedFields indexOfObjectPassingTest:^BOOL(RptqQueryField *obj, NSUInteger __unused i, BOOL * __unused stop) {
		return obj.identifier == field.identifier;
	}];
	if (idx == NSNotFound) {
		return [self convertRect:NSMakeRect(0.0, kCardTitleBarHeight, self.bounds.size.width, kCardFieldRowHeight) toView:canvasView];
	}
	NSRect rowRectInTable = [_tableView rectOfRow:(NSInteger)idx];
	NSRect rowRectInCard = [_tableView convertRect:rowRectInTable toView:self];

	// Clamp to visible scroll area (matches repositionRect in MADQueryVisualizationViewController.m:984-990)
	CGFloat minY = NSMinY(_scrollView.frame);
	CGFloat maxY = NSMaxY(_scrollView.frame) - rowRectInCard.size.height;
	if (rowRectInCard.origin.y < minY) {
		rowRectInCard.origin.y = minY;
	} else if (rowRectInCard.origin.y > maxY) {
		rowRectInCard.origin.y = MAX(minY, maxY);
	}
	rowRectInCard.origin.x = 0.0;
	rowRectInCard.size.width = self.bounds.size.width;
	return [self convertRect:rowRectInCard toView:canvasView];
}

- (nullable RptqQueryField *)queryFieldAtCanvasPoint:(NSPoint)canvasPoint rowOut:(nullable NSInteger *)rowOut {
	NSPoint ptInCard = [self convertPoint:canvasPoint fromView:_canvasView];
	if (!NSPointInRect(ptInCard, _scrollView.frame)) {
		if (rowOut) *rowOut = -1;
		return nil;
	}
	NSPoint ptInTable = [_tableView convertPoint:canvasPoint fromView:_canvasView];
	NSInteger row = [_tableView rowAtPoint:ptInTable];
	if (row < 0 || (NSUInteger)row >= _orderedFields.count) {
		if (rowOut) *rowOut = -1;
		return nil;
	}
	if (rowOut) *rowOut = row;
	return _orderedFields[(NSUInteger)row];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *) __unused tableView {
	return (NSInteger)_orderedFields.count;
}

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *) __unused tableColumn row:(NSInteger)row {
	if (row < 0 || (NSUInteger)row >= _orderedFields.count) return nil;
	RptqQueryField *qf = _orderedFields[(NSUInteger)row];
	NSString *fieldName = qf.databaseSchemaField.name ?: @"Field";

	BOOL isLinked = [_controller isQueryFieldLinked:qf];
	BOOL isGrouped = [_controller isQueryFieldGrouped:qf];
	BOOL isFiltered = [_controller isQueryFieldFiltered:qf];
	BOOL isDropTarget = (row == _highlightedTargetRow);

	NSTableCellView *cell = [tableView makeViewWithIdentifier:@"FieldCell" owner:self];
	NSTextField *label = nil;
	if (cell == nil) {
		cell = [[NSTableCellView alloc] initWithFrame:NSMakeRect(0.0, 0.0, tableView.bounds.size.width, kCardFieldRowHeight)];
		cell.identifier = @"FieldCell";
		cell.wantsLayer = YES;

		label = [NSTextField labelWithString:@""];
		label.lineBreakMode = NSLineBreakByTruncatingTail;
		label.translatesAutoresizingMaskIntoConstraints = NO;
		cell.textField = label;
		[cell addSubview:label];

		[NSLayoutConstraint activateConstraints:@[
			[label.leadingAnchor constraintEqualToAnchor:cell.leadingAnchor constant:8.0],
			[label.trailingAnchor constraintEqualToAnchor:cell.trailingAnchor constant:-8.0],
			[label.centerYAnchor constraintEqualToAnchor:cell.centerYAnchor],
		]];
	} else {
		label = cell.textField;
	}

	NSMutableString *display = [NSMutableString stringWithFormat:@"%@  %@", isLinked ? @"●" : @"○", fieldName];
	if (isGrouped) [display appendString:@"  [GRP]"];
	if (isFiltered) [display appendString:@"  [WHERE]"];
	label.stringValue = display;
	label.toolTip = [NSString stringWithFormat:@"%@.%@ — Drag to a field in another table to create a Left Outer Join",
					 _queryTable.alias ?: _queryTable.databaseSchemaTable.name ?: @"", fieldName];

	if (isDropTarget) {
		cell.layer.backgroundColor = [[[NSColor controlAccentColor] colorWithAlphaComponent:0.25] CGColor];
		label.font = [NSFont boldSystemFontOfSize:11.5];
		label.textColor = [NSColor controlAccentColor];
	} else {
		cell.layer.backgroundColor = [[NSColor clearColor] CGColor];
		label.font = (isLinked || isGrouped || isFiltered)
			? [NSFont systemFontOfSize:11.0 weight:NSFontWeightSemibold]
			: [NSFont systemFontOfSize:11.0 weight:NSFontWeightRegular];
		label.textColor = isLinked ? ([MADColorEverydayApps newColorRed] ?: [NSColor labelColor]) : [NSColor labelColor];
	}
	return cell;
}

@end

#pragma mark - MADMacQueryLinksOverlayView Implementation (MADConnectorView Equivalent)

static NSPoint MADCubicBezierPoint(NSPoint p0, NSPoint c1, NSPoint c2, NSPoint p3, CGFloat t) {
	CGFloat u = 1.0 - t;
	CGFloat tt = t * t;
	CGFloat uu = u * u;
	CGFloat uuu = uu * u;
	CGFloat ttt = tt * t;
	return NSMakePoint(uuu * p0.x + 3.0 * uu * t * c1.x + 3.0 * u * tt * c2.x + ttt * p3.x,
					   uuu * p0.y + 3.0 * uu * t * c1.y + 3.0 * u * tt * c2.y + ttt * p3.y);
}

static NSString *ShortBadgeTitleForLinkType(MADLinkType type) {
	switch (type) {
		case MADLinkTypeInnerJoin:      return @"INNER";
		case MADLinkTypeEquiJoin:       return @"EQUI";
		case MADLinkTypeNaturalJoin:    return @"NATURAL";
		case MADLinkTypeCrossJoin:      return @"CROSS";
		case MADLinkTypeRightOuterJoin: return @"RIGHT OUTER";
		case MADLinkTypeFullOuterJoin:  return @"FULL OUTER";
		case MADLinkTypeLeftOuterJoin:
		default:                        return @"LEFT OUTER";
	}
}

@implementation MADMacQueryLinksOverlayView

- (BOOL)isFlipped {
	return YES;
}

- (BOOL)acceptsFirstMouse:(nullable NSEvent *) __unused event {
	return YES;
}

- (nullable NSView *)hitTest:(NSPoint)point {
	// Convert point from superview (canvasView) coordinates to self
	NSPoint localPt = [self convertPoint:point fromView:self.superview];
	MADMacQueryLinkGeometry *hit = [_canvasView linkGeometryAtCanvasPoint:localPt];
	if (hit != nil) {
		return self;
	}
	return nil;
}

- (void)mouseDown:(NSEvent *)event {
	NSPoint pt = [self convertPoint:event.locationInWindow fromView:nil];
	MADMacQueryLinkGeometry *geom = [_canvasView linkGeometryAtCanvasPoint:pt];
	if (geom != nil) {
		[_canvasView.controller selectQueryLink:geom.link showPopover:YES];
	} else {
		[_canvasView.controller selectQueryLink:nil showPopover:NO];
	}
}

- (nullable NSMenu *)menuForEvent:(NSEvent *)event {
	NSPoint pt = [self convertPoint:event.locationInWindow fromView:nil];
	MADMacQueryLinkGeometry *geom = [_canvasView linkGeometryAtCanvasPoint:pt];
	if (geom == nil) return nil;
	[_canvasView.controller selectQueryLink:geom.link showPopover:NO];
	return [_canvasView.controller contextMenuForQueryLink:geom.link];
}

- (void)drawConnectorFrom:(NSPoint)origin
					   to:(NSPoint)destination
				 control1:(NSPoint)c1
				 control2:(NSPoint)c2
			leftIsInitial:(BOOL)leftIsInitial
					color:(NSColor *)strokeColor
			   isSelected:(BOOL)isSelected
			   badgeTitle:(nullable NSString *)badgeTitle
				badgeRect:(NSRect)badgeRect {
	CGContextRef ctx = [[NSGraphicsContext currentContext] CGContext];
	if (ctx == NULL) return;

	[NSGraphicsContext saveGraphicsState];
	CGContextSetShadowWithColor(ctx, CGSizeMake(1.5, -1.5), 4.0,
								[[[NSColor blackColor] colorWithAlphaComponent:0.28] CGColor]);

	if (isSelected) {
		[[[NSColor controlAccentColor] colorWithAlphaComponent:0.35] setStroke];
		NSBezierPath *halo = [NSBezierPath bezierPath];
		[halo moveToPoint:origin];
		[halo curveToPoint:destination controlPoint1:c1 controlPoint2:c2];
		halo.lineWidth = 7.0;
		halo.lineCapStyle = NSLineCapStyleRound;
		[halo stroke];
	}

	[strokeColor setStroke];
	[strokeColor setFill];

	// Bezier curve (matches MADConnectorView.m:132-139)
	NSBezierPath *curve = [NSBezierPath bezierPath];
	[curve moveToPoint:origin];
	[curve curveToPoint:destination controlPoint1:c1 controlPoint2:c2];
	curve.lineWidth = 3.0;
	curve.lineCapStyle = NSLineCapStyleRound;
	[curve stroke];

	// Endpoint nobs (matches MADConnectorView.m:125-130)
	NSRect nob0 = NSMakeRect(origin.x - 3.5, origin.y - 3.5, 7.0, 7.0);
	NSRect nob1 = NSMakeRect(destination.x - 3.5, destination.y - 3.5, 7.0, 7.0);
	[[NSBezierPath bezierPathWithOvalInRect:nob0] fill];
	[[NSBezierPath bezierPathWithOvalInRect:nob1] fill];

	// Directional chevron / crow's foot at destination (matches MADConnectorView.m:97-144)
	CGFloat dir = leftIsInitial ? -1.0 : 1.0;
	NSBezierPath *arrow = [NSBezierPath bezierPath];
	[arrow moveToPoint:NSMakePoint(destination.x + dir * 9.0, destination.y - 5.5)];
	[arrow lineToPoint:NSMakePoint(destination.x + dir * 2.0, destination.y)];
	[arrow lineToPoint:NSMakePoint(destination.x + dir * 9.0, destination.y + 5.5)];
	arrow.lineWidth = 2.5;
	arrow.lineCapStyle = NSLineCapStyleRound;
	arrow.lineJoinStyle = NSLineJoinStyleRound;
	[arrow stroke];

	// Clickable Join-Type Badge at midpoint
	if (badgeTitle.length > 0 && !NSIsEmptyRect(badgeRect)) {
		NSBezierPath *pill = [NSBezierPath bezierPathWithRoundedRect:badgeRect xRadius:8.0 yRadius:8.0];
		NSColor *pillBg = isSelected ? [NSColor controlAccentColor] : [NSColor windowBackgroundColor];
		[pillBg setFill];
		[pill fill];

		NSColor *pillBorder = isSelected ? [NSColor whiteColor] : strokeColor;
		[pillBorder setStroke];
		pill.lineWidth = isSelected ? 1.8 : 1.25;
		[pill stroke];

		NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];
		pStyle.alignment = NSTextAlignmentCenter;
		NSDictionary *attrs = @{
			NSFontAttributeName: [NSFont systemFontOfSize:9.5 weight:NSFontWeightBold],
			NSForegroundColorAttributeName: isSelected ? [NSColor whiteColor] : strokeColor,
			NSParagraphStyleAttributeName: pStyle,
		};
		NSRect textRect = NSMakeRect(badgeRect.origin.x + 4.0, badgeRect.origin.y + 2.0,
									 badgeRect.size.width - 8.0, badgeRect.size.height - 3.0);
		[badgeTitle drawInRect:textRect withAttributes:attrs];
	}

	[NSGraphicsContext restoreGraphicsState];
}

- (void)drawRect:(NSRect) __unused dirtyRect {
	NSColor *connectorRed = [MADColorEverydayApps newColorRed] ?: [NSColor systemRedColor];
	NSArray<MADMacQueryLinkGeometry *> *geoms = [_canvasView computedLinkGeometries];
	for (MADMacQueryLinkGeometry *g in geoms) {
		BOOL selected = (g.link.identifier == _canvasView.selectedLinkID);
		NSColor *color = selected ? [NSColor controlAccentColor] : connectorRed;
		NSString *badge = ShortBadgeTitleForLinkType((MADLinkType)g.link.type);
		[self drawConnectorFrom:g.origin
							 to:g.destination
					   control1:g.control1
					   control2:g.control2
				  leftIsInitial:g.leftIsInitial
						  color:color
					 isSelected:selected
					 badgeTitle:badge
					  badgeRect:g.badgeRect];
	}

	// Draw live rubber-band connection curve while dragging from a field in one table to another
	if (_canvasView.isDraggingConnection && _canvasView.dragSourceCard != nil && _canvasView.dragSourceField != nil) {
		NSRect srcRowRect = [_canvasView.dragSourceCard rectForQueryField:_canvasView.dragSourceField inCanvas:_canvasView];
		NSPoint endPt = _canvasView.dragCurrentCanvasPoint;
		if (_canvasView.dragTargetCard != nil && _canvasView.dragTargetField != nil) {
			NSRect dstRowRect = [_canvasView.dragTargetCard rectForQueryField:_canvasView.dragTargetField inCanvas:_canvasView];
			BOOL leftInit = (NSMidX(_canvasView.dragSourceCard.frame) <= NSMidX(_canvasView.dragTargetCard.frame));
			endPt = NSMakePoint(leftInit ? NSMinX(_canvasView.dragTargetCard.frame) : NSMaxX(_canvasView.dragTargetCard.frame),
								NSMidY(dstRowRect));
		}
		BOOL leftIsInitial = (endPt.x >= NSMidX(_canvasView.dragSourceCard.frame));
		NSPoint startPt = NSMakePoint(leftIsInitial ? NSMaxX(_canvasView.dragSourceCard.frame) : NSMinX(_canvasView.dragSourceCard.frame),
									  NSMidY(srcRowRect));
		CGFloat dx = MAX(fabs(endPt.x - startPt.x) * 0.45, 40.0);
		NSPoint c1 = NSMakePoint(leftIsInitial ? startPt.x + dx : startPt.x - dx, startPt.y);
		NSPoint c2 = NSMakePoint(leftIsInitial ? endPt.x - dx : endPt.x + dx, endPt.y);
		NSPoint mid = MADCubicBezierPoint(startPt, c1, c2, endPt, 0.5);
		NSRect badgeRect = NSMakeRect(mid.x - 38.0, mid.y - 9.0, 76.0, 18.0);
		[self drawConnectorFrom:startPt
							 to:endPt
					   control1:c1
					   control2:c2
				  leftIsInitial:leftIsInitial
						  color:connectorRed
					 isSelected:NO
					 badgeTitle:@"LEFT OUTER"
					  badgeRect:badgeRect];
	}
}

@end

#pragma mark - MADMacQueryCanvasView Implementation

@implementation MADMacQueryCanvasView

- (BOOL)isFlipped {
	return YES;
}

- (BOOL)acceptsFirstResponder {
	return YES;
}

- (instancetype)initWithFrame:(NSRect)frame {
	if (self = [super initWithFrame:frame]) {
		_cardsByTableID = [[NSMutableDictionary alloc] init];
		_cachedFramesByTableID = [[NSMutableDictionary alloc] init];
		_queryTables = @[];
		_queryLinks = @[];

		_linksOverlayView = [[MADMacQueryLinksOverlayView alloc] initWithFrame:self.bounds];
		_linksOverlayView.canvasView = self;
		_linksOverlayView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
		[self addSubview:_linksOverlayView];
	}
	return self;
}

- (void)selectCardBringToFront:(MADMacQueryTableCardView *)card {
	if (card == nil) return;
	[self addSubview:card positioned:NSWindowAbove relativeTo:nil];
	[self addSubview:_linksOverlayView positioned:NSWindowAbove relativeTo:nil];
	[_linksOverlayView setNeedsDisplay:YES];
}

- (void)cardDidMoveOrScroll:(MADMacQueryTableCardView *) __unused card {
	[_controller dismissActiveLinkPopover];
	[_linksOverlayView setNeedsDisplay:YES];
}

- (void)ensureCanvasSizeFitsCards {
	CGFloat minW = 900.0;
	CGFloat minH = 640.0;
	if (self.enclosingScrollView != nil) {
		NSSize contentSize = self.enclosingScrollView.contentSize;
		minW = MAX(minW, contentSize.width);
		minH = MAX(minH, contentSize.height);
	}
	for (MADMacQueryTableCardView *card in _cardsByTableID.allValues) {
		minW = MAX(minW, NSMaxX(card.frame) + 80.0);
		minH = MAX(minH, NSMaxY(card.frame) + 80.0);
	}
	if (fabs(self.frame.size.width - minW) > 1.0 || fabs(self.frame.size.height - minH) > 1.0) {
		self.frame = NSMakeRect(0.0, 0.0, minW, minH);
		_linksOverlayView.frame = self.bounds;
	}
}

- (void)rebuildCanvasWithTables:(NSArray<RptqQueryTable *> *)tables
						  links:(NSArray<RptqQueryLinks *> *)links
					rootTableID:(NSSet<NSNumber *> *)rootTableIDs {
	_queryTables = [tables copy];
	_queryLinks = [links copy];

	NSMutableSet<NSNumber *> *activeIDs = [NSMutableSet setWithCapacity:tables.count];
	for (RptqQueryTable *qt in tables) {
		[activeIDs addObject:@(qt.identifier)];
	}

	// Remove cards for deleted tables
	for (NSNumber *existingID in [_cardsByTableID.allKeys copy]) {
		if (![activeIDs containsObject:existingID]) {
			MADMacQueryTableCardView *oldCard = _cardsByTableID[existingID];
			[oldCard removeFromSuperview];
			[_cardsByTableID removeObjectForKey:existingID];
		}
	}

	// Create or update cards for current tables
	NSUInteger idx = 0;
	for (RptqQueryTable *qt in tables) {
		NSNumber *key = @(qt.identifier);
		MADMacQueryTableCardView *card = _cardsByTableID[key];
		BOOL isRoot = [rootTableIDs containsObject:key];
		if (card == nil) {
			NSValue *cachedFrameVal = _cachedFramesByTableID[key];
			NSRect cardFrame;
			if (cachedFrameVal != nil) {
				cardFrame = cachedFrameVal.rectValue;
			} else {
				NSUInteger col = idx % 3;
				NSUInteger row = idx / 3;
				CGFloat x = 48.0 + (CGFloat)col * (kDefaultCardWidth + 96.0);
				CGFloat y = 44.0 + (CGFloat)row * (kDefaultCardHeight + 52.0);
				cardFrame = NSMakeRect(x, y, kDefaultCardWidth, kDefaultCardHeight);
				_cachedFramesByTableID[key] = [NSValue valueWithRect:cardFrame];
			}
			card = [[MADMacQueryTableCardView alloc] initWithFrame:cardFrame
														queryTable:qt
														controller:_controller
														canvasView:self];
			_cardsByTableID[key] = card;
			[self addSubview:card positioned:NSWindowBelow relativeTo:_linksOverlayView];
		} else {
			card.queryTable = qt;
			[card reloadFields];
		}
		card.isRootTable = isRoot;
		idx++;
	}

	[self addSubview:_linksOverlayView positioned:NSWindowAbove relativeTo:nil];
	[self ensureCanvasSizeFitsCards];
	[self setNeedsDisplay:YES];
	[_linksOverlayView setNeedsDisplay:YES];
}

- (void)autoArrangeCardsWithTopologicalOrder:(NSArray<NSNumber *> *)orderedTableIDs
								rootTableIDs:(NSSet<NSNumber *> *)rootTableIDs {
	NSUInteger idx = 0;
	for (NSNumber *tableID in orderedTableIDs) {
		MADMacQueryTableCardView *card = _cardsByTableID[tableID];
		if (card == nil) continue;
		NSUInteger col = idx % 3;
		NSUInteger row = idx / 3;
		CGFloat x = 48.0 + (CGFloat)col * (kDefaultCardWidth + 96.0);
		CGFloat y = 44.0 + (CGFloat)row * (kDefaultCardHeight + 52.0);
		NSRect frame = NSMakeRect(x, y, NSWidth(card.frame), NSHeight(card.frame));
		card.frame = frame;
		card.isRootTable = [rootTableIDs containsObject:tableID];
		_cachedFramesByTableID[tableID] = [NSValue valueWithRect:frame];
		idx++;
	}
	[self ensureCanvasSizeFitsCards];
	[_linksOverlayView setNeedsDisplay:YES];
}

- (NSArray<MADMacQueryLinkGeometry *> *)computedLinkGeometries {
	NSMutableArray<MADMacQueryLinkGeometry *> *result = [NSMutableArray arrayWithCapacity:_queryLinks.count];
	for (RptqQueryLinks *link in _queryLinks) {
		RptqQueryField *leftField = link.hasLeftField;
		RptqQueryField *rightField = link.hasRightField;
		if (leftField == nil || rightField == nil) continue;

		MADMacQueryTableCardView *leftCard = _cardsByTableID[@(leftField.inQueryTable.identifier)];
		MADMacQueryTableCardView *rightCard = _cardsByTableID[@(rightField.inQueryTable.identifier)];
		if (leftCard == nil || rightCard == nil) continue;

		NSRect leftRowRect = [leftCard rectForQueryField:leftField inCanvas:self];
		NSRect rightRowRect = [rightCard rectForQueryField:rightField inCanvas:self];

		BOOL leftIsInitial = (NSMidX(leftCard.frame) <= NSMidX(rightCard.frame));
		NSPoint origin = NSMakePoint(leftIsInitial ? NSMaxX(leftCard.frame) : NSMinX(leftCard.frame),
									 NSMidY(leftRowRect));
		NSPoint destination = NSMakePoint(leftIsInitial ? NSMinX(rightCard.frame) : NSMaxX(rightCard.frame),
										  NSMidY(rightRowRect));

		CGFloat dx = MAX(fabs(destination.x - origin.x) * 0.45, 44.0);
		NSPoint c1 = NSMakePoint(leftIsInitial ? origin.x + dx : origin.x - dx, origin.y);
		NSPoint c2 = NSMakePoint(leftIsInitial ? destination.x - dx : destination.x + dx, destination.y);
		NSPoint mid = MADCubicBezierPoint(origin, c1, c2, destination, 0.5);

		NSString *badge = ShortBadgeTitleForLinkType((MADLinkType)link.type);
		CGFloat badgeW = MAX(56.0, (CGFloat)badge.length * 6.5 + 14.0);
		NSRect badgeRect = NSMakeRect(mid.x - badgeW * 0.5, mid.y - 9.0, badgeW, 18.0);

		MADMacQueryLinkGeometry *g = [[MADMacQueryLinkGeometry alloc] init];
		g.link = link;
		g.origin = origin;
		g.destination = destination;
		g.control1 = c1;
		g.control2 = c2;
		g.midpoint = mid;
		g.badgeRect = badgeRect;
		g.leftIsInitial = leftIsInitial;
		[result addObject:g];
	}
	return result;
}

- (nullable MADMacQueryLinkGeometry *)linkGeometryAtCanvasPoint:(NSPoint)point {
	NSArray<MADMacQueryLinkGeometry *> *geoms = [self computedLinkGeometries];
	for (MADMacQueryLinkGeometry *g in [geoms reverseObjectEnumerator]) {
		if (NSPointInRect(point, NSInsetRect(g.badgeRect, -4.0, -4.0))) {
			return g;
		}
		const NSInteger steps = 32;
		for (NSInteger i = 0; i <= steps; i++) {
			CGFloat t = (CGFloat)i / (CGFloat)steps;
			NSPoint p = MADCubicBezierPoint(g.origin, g.control1, g.control2, g.destination, t);
			if (hypot(point.x - p.x, point.y - p.y) <= 8.0) {
				return g;
			}
		}
	}
	return nil;
}

- (void)beginFieldConnectionDragFromCard:(MADMacQueryTableCardView *)card field:(RptqQueryField *)field {
	[_controller dismissActiveLinkPopover];
	_isDraggingConnection = YES;
	_dragSourceCard = card;
	_dragSourceField = field;
	_dragTargetCard = nil;
	_dragTargetField = nil;
	NSRect rowRect = [card rectForQueryField:field inCanvas:self];
	_dragCurrentCanvasPoint = NSMakePoint(NSMaxX(card.frame), NSMidY(rowRect));
	[_linksOverlayView setNeedsDisplay:YES];
}

- (void)updateFieldConnectionDragToPoint:(NSPoint)canvasPoint {
	_dragCurrentCanvasPoint = canvasPoint;
	MADMacQueryTableCardView *foundCard = nil;
	RptqQueryField *foundField = nil;
	NSInteger foundRow = -1;

	for (MADMacQueryTableCardView *card in _cardsByTableID.allValues) {
		if (card == _dragSourceCard) continue;
		if (NSPointInRect(canvasPoint, card.frame)) {
			NSInteger r = -1;
			RptqQueryField *qf = [card queryFieldAtCanvasPoint:canvasPoint rowOut:&r];
			if (qf != nil) {
				foundCard = card;
				foundField = qf;
				foundRow = r;
				break;
			}
		}
	}

	if (_dragTargetCard != foundCard) {
		_dragTargetCard.highlightedTargetRow = -1;
		_dragTargetCard = foundCard;
	}
	if (_dragTargetCard != nil) {
		_dragTargetCard.highlightedTargetRow = foundRow;
	}
	_dragTargetField = foundField;
	[_linksOverlayView setNeedsDisplay:YES];
}

- (void)finishFieldConnectionDragAtPoint:(NSPoint)canvasPoint {
	[self updateFieldConnectionDragToPoint:canvasPoint];
	RptqQueryField *src = _dragSourceField;
	RptqQueryField *dst = _dragTargetField;
	_dragTargetCard.highlightedTargetRow = -1;

	_isDraggingConnection = NO;
	_dragSourceCard = nil;
	_dragSourceField = nil;
	_dragTargetCard = nil;
	_dragTargetField = nil;
	[_linksOverlayView setNeedsDisplay:YES];

	if (src != nil && dst != nil && src.inQueryTable.identifier != dst.inQueryTable.identifier) {
		RptqQueryLinks *created = [_controller connectQueryField:src toQueryField:dst];
		if (created != nil) {
			[_controller selectQueryLink:created showPopover:NO];
		}
	}
}

- (void)mouseDown:(NSEvent *) __unused event {
	[self.window makeFirstResponder:self];
	[_controller selectQueryLink:nil showPopover:NO];
}

- (void)keyDown:(NSEvent *)event {
	NSString *chars = event.charactersIgnoringModifiers;
	if (chars.length > 0) {
		unichar ch = [chars characterAtIndex:0];
		if ((ch == NSDeleteCharacter || ch == NSBackspaceCharacter || ch == NSDeleteFunctionKey) && _selectedLinkID != 0) {
			for (RptqQueryLinks *link in _queryLinks) {
				if (link.identifier == _selectedLinkID) {
					[_controller deleteQueryLink:link];
					return;
				}
			}
		}
	}
	[super keyDown:event];
}

- (void)drawRect:(NSRect)dirtyRect {
	[[NSColor underPageBackgroundColor] setFill];
	NSRectFill(dirtyRect);

	// Subtle grid dots on the canvas
	[[[NSColor separatorColor] colorWithAlphaComponent:0.35] setFill];
	const CGFloat step = 24.0;
	CGFloat startX = floor(NSMinX(dirtyRect) / step) * step;
	CGFloat startY = floor(NSMinY(dirtyRect) / step) * step;
	for (CGFloat y = startY; y < NSMaxY(dirtyRect); y += step) {
		for (CGFloat x = startX; x < NSMaxX(dirtyRect); x += step) {
			if (x >= 12.0 && y >= 12.0) {
				NSRectFill(NSMakeRect(x, y, 1.5, 1.5));
			}
		}
	}

	if (_queryTables.count == 0) {
		NSString *emptyMsg = @"Double-click a table on the left to add it to the visual query designer.\nDrag from a field in one table to a field in another table to create a Left Outer Join.";
		NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];
		pStyle.alignment = NSTextAlignmentCenter;
		pStyle.lineSpacing = 4.0;
		NSDictionary *attrs = @{
			NSFontAttributeName: [NSFont systemFontOfSize:13.5 weight:NSFontWeightMedium],
			NSForegroundColorAttributeName: [NSColor secondaryLabelColor],
			NSParagraphStyleAttributeName: pStyle,
		};
		NSRect b = self.enclosingScrollView ? self.enclosingScrollView.documentVisibleRect : self.bounds;
		NSRect msgRect = NSMakeRect(b.origin.x + 40.0, b.origin.y + b.size.height * 0.42, MAX(260.0, b.size.width - 80.0), 64.0);
		[emptyMsg drawInRect:msgRect withAttributes:attrs];
	}
}

@end

#pragma mark - MADMacQueryViewController Extension & Implementation

@interface MADMacQueryViewController () <NSSplitViewDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, assign, readwrite) MADMacQueryWorkspaceMode workspaceMode;
@property (nonatomic, assign, readwrite) CGFloat schemaSidebarWidth;

// Top bar controls
@property (nonatomic, strong) NSView *topBarView;
@property (nonatomic, strong) NSSegmentedControl *modeSegmentedControl;
@property (nonatomic, strong) NSStackView *designerHeaderControls;
@property (nonatomic, strong) NSButton *filtersButton;
@property (nonatomic, strong) NSButton *groupsButton;
@property (nonatomic, strong) NSButton *arrangeButton;
@property (nonatomic, strong) NSStackView *sqlHeaderControls;

// Mode 0: Visual Query Designer (NSSplitView: 200px Schema Sidebar + Visual Canvas)
@property (nonatomic, strong) NSSplitView *designerSplitView;
@property (nonatomic, strong) NSView *schemaSidebarView;
@property (nonatomic, strong) NSTableView *schemaTablesTable;
@property (nonatomic, strong) NSView *canvasContainerView;
@property (nonatomic, strong) NSScrollView *canvasScrollView;
@property (nonatomic, strong) MADMacQueryCanvasView *canvasView;

// Mode 1: SQL Query Editor (Mutually exclusive with Visual Query Designer)
@property (nonatomic, strong) NSView *sqlEditorContainerView;
@property (nonatomic, strong) NSSegmentedControl *sqlSourceTabControl;
@property (nonatomic, strong) NSTextView *sqlTextView;
@property (nonatomic, strong) NSTextField *sqlStatusLabel;

// Popovers for Link Type Editing, Filters (WHERE), and Groupings (GROUP BY)
@property (nonatomic, strong, nullable) NSPopover *activeLinkPopover;
@property (nonatomic, strong, nullable) NSPopover *filtersPopover;
@property (nonatomic, strong, nullable) NSPopover *groupsPopover;

// Popover tables & controls
@property (nonatomic, strong, nullable) NSTableView *predicatesTable;
@property (nonatomic, strong, nullable) NSPopUpButton *predicateFieldPopup;
@property (nonatomic, strong, nullable) NSPopUpButton *predicateOperatorPopup;
@property (nonatomic, strong, nullable) NSTextField *predicateValueField;

@property (nonatomic, strong, nullable) NSTableView *groupsTable;
@property (nonatomic, strong, nullable) NSPopUpButton *groupFieldPopup;
@property (nonatomic, strong, nullable) NSPopUpButton *groupSortPopup;

// Model snapshots
@property (nonatomic, copy) NSArray<RptqDatabaseSchemaTable *> *schemaTables;
@property (nonatomic, copy) NSArray<RptqQueryTable *> *queryTables;
@property (nonatomic, copy) NSArray<RptqQueryField *> *queryFields;
@property (nonatomic, copy) NSArray<RptqQueryLinks *> *queryLinks;
@property (nonatomic, copy) NSArray<RptqQueryPredicate *> *queryPredicates;
@property (nonatomic, copy) NSArray<RptqQueryGroup *> *queryGroups;

@end

@implementation MADMacQueryViewController

- (instancetype)initWithDocument:(MADMacDocument *)document {
	if (self = [super initWithNibName:nil bundle:nil]) {
		_document = document;
		_workspaceMode = MADMacQueryWorkspaceModeDesigner;
		_schemaSidebarWidth = kDefaultSidebarWidth;
		_schemaTables = @[];
		_queryTables = @[];
		_queryFields = @[];
		_queryLinks = @[];
		_queryPredicates = @[];
		_queryGroups = @[];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (int64_t)selectedLinkIdentifier {
	return _canvasView.selectedLinkID;
}

- (nullable NSView *)tableCardViewForQueryTableID:(int64_t)queryTableID {
	return _canvasView.cardsByTableID[@(queryTableID)];
}

#pragma mark - View Construction

- (void)loadView {
	NSRect rootRect = NSMakeRect(0.0, 0.0, 1180.0, 740.0);
	NSView *root = [[NSView alloc] initWithFrame:rootRect];
	root.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

	// 1. Top Workspace Bar (Mode Switcher + Contextual Controls)
	_topBarView = [[NSView alloc] initWithFrame:NSMakeRect(0.0, rootRect.size.height - kTopBarHeight, rootRect.size.width, kTopBarHeight)];
	_topBarView.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
	[self populateTopBar:_topBarView];

	NSBox *topDivider = [[NSBox alloc] initWithFrame:NSMakeRect(0.0, rootRect.size.height - kTopBarHeight, rootRect.size.width, 1.0)];
	topDivider.boxType = NSBoxSeparator;
	topDivider.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;

	// 2. Content Area below Top Bar
	NSRect contentRect = NSMakeRect(0.0, 0.0, rootRect.size.width, rootRect.size.height - kTopBarHeight);

	// 2a. Visual Query Designer Split View (Left 200px Schema Table List | Right Visual Canvas)
	_designerSplitView = [[NSSplitView alloc] initWithFrame:contentRect];
	_designerSplitView.vertical = YES;
	_designerSplitView.dividerStyle = NSSplitViewDividerStyleThin;
	_designerSplitView.delegate = self;
	_designerSplitView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

	_schemaSidebarView = [[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, _schemaSidebarWidth, contentRect.size.height)];
	_schemaSidebarView.autoresizingMask = NSViewHeightSizable;
	[self populateSchemaSidebar:_schemaSidebarView];

	CGFloat divider = _designerSplitView.dividerThickness;
	CGFloat rightW = MAX(320.0, contentRect.size.width - _schemaSidebarWidth - divider);
	_canvasContainerView = [[NSView alloc] initWithFrame:NSMakeRect(_schemaSidebarWidth + divider, 0.0, rightW, contentRect.size.height)];
	_canvasContainerView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	[self populateCanvasContainer:_canvasContainerView];

	[_designerSplitView addSubview:_schemaSidebarView];
	[_designerSplitView addSubview:_canvasContainerView];
	[_designerSplitView setHoldingPriority:NSLayoutPriorityDefaultHigh forSubviewAtIndex:0];
	[_designerSplitView setHoldingPriority:NSLayoutPriorityDefaultLow - 1 forSubviewAtIndex:1];
	[_designerSplitView setPosition:_schemaSidebarWidth ofDividerAtIndex:0];

	// 2b. SQL Editor Container View (Mutually exclusive with _designerSplitView)
	_sqlEditorContainerView = [[NSView alloc] initWithFrame:contentRect];
	_sqlEditorContainerView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	_sqlEditorContainerView.hidden = YES;
	[self populateSQLEditorContainer:_sqlEditorContainerView];

	[root addSubview:_designerSplitView];
	[root addSubview:_sqlEditorContainerView];
	[root addSubview:_topBarView];
	[root addSubview:topDivider];

	self.view = root;
}

- (void)populateTopBar:(NSView *)bar {
	_modeSegmentedControl = [NSSegmentedControl segmentedControlWithLabels:@[@"Query Designer", @"SQL Query"]
															  trackingMode:NSSegmentSwitchTrackingSelectOne
																	target:self
																	action:@selector(modeSegmentChanged:)];
	_modeSegmentedControl.selectedSegment = MADMacQueryWorkspaceModeDesigner;
	_modeSegmentedControl.translatesAutoresizingMaskIntoConstraints = NO;

	_filtersButton = [NSButton buttonWithTitle:@"Filters (WHERE)"
										target:self
										action:@selector(toggleFiltersPopover:)];
	_groupsButton = [NSButton buttonWithTitle:@"Groupings (GROUP BY)"
									   target:self
									   action:@selector(toggleGroupsPopover:)];
	_arrangeButton = [NSButton buttonWithTitle:@"Arrange Tables"
										target:self
										action:@selector(autoArrangeTablesAction:)];

	_designerHeaderControls = [NSStackView stackViewWithViews:@[_filtersButton, _groupsButton, _arrangeButton]];
	_designerHeaderControls.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	_designerHeaderControls.spacing = 8.0;
	_designerHeaderControls.translatesAutoresizingMaskIntoConstraints = NO;

	NSButton *revertSQLBtn = [NSButton buttonWithTitle:@"Revert to Generated SQL"
												target:self
												action:@selector(syncSQLFromVisualQuery:)];
	NSButton *validateSQLBtn = [NSButton buttonWithTitle:@"Validate SQL"
												  target:self
												  action:@selector(validateSQLAction:)];
	NSButton *applySQLBtn = [NSButton buttonWithTitle:@"Compile & Apply SQL"
											   target:self
											   action:@selector(compileAndApplySQL:)];
	applySQLBtn.bezelColor = [NSColor controlAccentColor];

	_sqlHeaderControls = [NSStackView stackViewWithViews:@[revertSQLBtn, validateSQLBtn, applySQLBtn]];
	_sqlHeaderControls.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	_sqlHeaderControls.spacing = 8.0;
	_sqlHeaderControls.translatesAutoresizingMaskIntoConstraints = NO;
	_sqlHeaderControls.hidden = YES;

	[bar addSubview:_modeSegmentedControl];
	[bar addSubview:_designerHeaderControls];
	[bar addSubview:_sqlHeaderControls];

	[NSLayoutConstraint activateConstraints:@[
		[_modeSegmentedControl.leadingAnchor constraintEqualToAnchor:bar.leadingAnchor constant:12.0],
		[_modeSegmentedControl.centerYAnchor constraintEqualToAnchor:bar.centerYAnchor],

		[_designerHeaderControls.trailingAnchor constraintEqualToAnchor:bar.trailingAnchor constant:-12.0],
		[_designerHeaderControls.centerYAnchor constraintEqualToAnchor:bar.centerYAnchor],

		[_sqlHeaderControls.trailingAnchor constraintEqualToAnchor:bar.trailingAnchor constant:-12.0],
		[_sqlHeaderControls.centerYAnchor constraintEqualToAnchor:bar.centerYAnchor],
	]];
}

- (void)populateSchemaSidebar:(NSView *)sidebar {
	NSRect b = sidebar.bounds;
	CGFloat headerH = 26.0;
	CGFloat footerH = 30.0;

	NSTextField *headerLabel = [NSTextField labelWithString:@"Database Tables"];
	headerLabel.font = [NSFont boldSystemFontOfSize:12.0];
	headerLabel.frame = NSMakeRect(10.0, b.size.height - headerH + 3.0, b.size.width - 20.0, 20.0);
	headerLabel.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
	[sidebar addSubview:headerLabel];

	NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0.0, footerH, b.size.width, b.size.height - headerH - footerH)];
	scroll.hasVerticalScroller = YES;
	scroll.hasHorizontalScroller = NO;
	scroll.autohidesScrollers = YES;
	scroll.borderType = NSNoBorder;
	scroll.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

	_schemaTablesTable = [[NSTableView alloc] initWithFrame:scroll.bounds];
	_schemaTablesTable.headerView = nil;
	_schemaTablesTable.usesAlternatingRowBackgroundColors = YES;
	_schemaTablesTable.rowHeight = 24.0;
	_schemaTablesTable.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;
	_schemaTablesTable.delegate = self;
	_schemaTablesTable.dataSource = self;
	_schemaTablesTable.target = self;
	_schemaTablesTable.doubleAction = @selector(handleDoubleClickSchemaTable:);

	NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:@"schema"];
	col.title = @"Database Tables";
	col.width = b.size.width;
	col.minWidth = 100.0;
	col.resizingMask = NSTableColumnAutoresizingMask;
	[_schemaTablesTable addTableColumn:col];

	scroll.documentView = _schemaTablesTable;
	[sidebar addSubview:scroll];

	NSBox *footerSep = [[NSBox alloc] initWithFrame:NSMakeRect(0.0, footerH - 1.0, b.size.width, 1.0)];
	footerSep.boxType = NSBoxSeparator;
	footerSep.autoresizingMask = NSViewWidthSizable | NSViewMaxYMargin;
	[sidebar addSubview:footerSep];

	NSButton *addBtn = [NSButton buttonWithTitle:@"+ Add Table to Query"
										  target:self
										  action:@selector(addSelectedSchemaTable:)];
	addBtn.controlSize = NSControlSizeSmall;
	addBtn.font = [NSFont systemFontOfSize:11.5];
	addBtn.frame = NSMakeRect(8.0, 4.0, b.size.width - 16.0, 22.0);
	addBtn.autoresizingMask = NSViewWidthSizable | NSViewMaxYMargin;
	[sidebar addSubview:addBtn];
}

- (void)populateCanvasContainer:(NSView *)container {
	_canvasScrollView = [[NSScrollView alloc] initWithFrame:container.bounds];
	_canvasScrollView.hasVerticalScroller = YES;
	_canvasScrollView.hasHorizontalScroller = YES;
	_canvasScrollView.autohidesScrollers = NO;
	_canvasScrollView.borderType = NSNoBorder;
	_canvasScrollView.backgroundColor = [NSColor underPageBackgroundColor];
	_canvasScrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

	_canvasView = [[MADMacQueryCanvasView alloc] initWithFrame:NSMakeRect(0.0, 0.0, MAX(960.0, container.bounds.size.width), MAX(680.0, container.bounds.size.height))];
	_canvasView.controller = self;
	_canvasScrollView.documentView = _canvasView;

	[container addSubview:_canvasScrollView];
}

- (void)populateSQLEditorContainer:(NSView *)container {
	NSTextField *titleLabel = [NSTextField labelWithString:@"SQL Query Statement"];
	titleLabel.font = [NSFont boldSystemFontOfSize:13.0];
	titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

	_sqlSourceTabControl = [NSSegmentedControl segmentedControlWithLabels:@[@"Generated SQL", @"As Entered"]
															 trackingMode:NSSegmentSwitchTrackingSelectOne
																   target:self
																   action:@selector(sqlSourceTabChanged:)];
	_sqlSourceTabControl.selectedSegment = 0;
	_sqlSourceTabControl.translatesAutoresizingMaskIntoConstraints = NO;
	_sqlSourceTabControl.hidden = YES;

	NSScrollView *sqlScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 800.0, 500.0)];
	sqlScroll.hasVerticalScroller = YES;
	sqlScroll.borderType = NSBezelBorder;
	sqlScroll.translatesAutoresizingMaskIntoConstraints = NO;

	_sqlTextView = [[NSTextView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 800.0, 500.0)];
	_sqlTextView.editable = YES;
	_sqlTextView.richText = NO;
	_sqlTextView.automaticQuoteSubstitutionEnabled = NO;
	_sqlTextView.automaticDashSubstitutionEnabled = NO;
	_sqlTextView.font = [NSFont monospacedSystemFontOfSize:13.0 weight:NSFontWeightRegular];
	_sqlTextView.textContainerInset = NSMakeSize(8.0, 8.0);
	_sqlTextView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	sqlScroll.documentView = _sqlTextView;

	_sqlStatusLabel = [NSTextField labelWithString:@"Enter a SELECT statement and click Compile & Apply SQL to update the query."];
	_sqlStatusLabel.font = [NSFont systemFontOfSize:12.0];
	_sqlStatusLabel.textColor = [NSColor secondaryLabelColor];
	_sqlStatusLabel.lineBreakMode = NSLineBreakByTruncatingTail;
	_sqlStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;

	[container addSubview:titleLabel];
	[container addSubview:_sqlSourceTabControl];
	[container addSubview:sqlScroll];
	[container addSubview:_sqlStatusLabel];

	[NSLayoutConstraint activateConstraints:@[
		[titleLabel.topAnchor constraintEqualToAnchor:container.topAnchor constant:14.0],
		[titleLabel.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:16.0],

		[_sqlSourceTabControl.centerYAnchor constraintEqualToAnchor:titleLabel.centerYAnchor],
		[_sqlSourceTabControl.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-16.0],

		[sqlScroll.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:10.0],
		[sqlScroll.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:16.0],
		[sqlScroll.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-16.0],
		[sqlScroll.bottomAnchor constraintEqualToAnchor:_sqlStatusLabel.topAnchor constant:-10.0],

		[_sqlStatusLabel.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:16.0],
		[_sqlStatusLabel.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-16.0],
		[_sqlStatusLabel.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-12.0],
	]];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleDocumentNotification:)
												 name:MADMacDocumentDidMutateNotification
											   object:_document];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleDocumentNotification:)
												 name:MADMacDocumentDidRefreshNotification
											   object:_document];
	[self reloadFromDocument];
}

- (void)handleDocumentNotification:(NSNotification *) __unused note {
	[self reloadFromDocument];
}

#pragma mark - Mode Switching (Mutually Exclusive Visual Designer vs. SQL Editor)

- (void)modeSegmentChanged:(NSSegmentedControl *)sender {
	[self switchToMode:(MADMacQueryWorkspaceMode)sender.selectedSegment];
}

- (void)switchToMode:(MADMacQueryWorkspaceMode)mode {
	_workspaceMode = mode;
	_modeSegmentedControl.selectedSegment = mode;

	BOOL isDesigner = (mode == MADMacQueryWorkspaceModeDesigner);
	_designerSplitView.hidden = !isDesigner;
	_designerHeaderControls.hidden = !isDesigner;

	_sqlEditorContainerView.hidden = isDesigner;
	_sqlHeaderControls.hidden = isDesigner;

	[self dismissActiveLinkPopover];
	if (!isDesigner) {
		[self syncSQLFromVisualQuery:nil];
	}
}

#pragma mark - NSSplitViewDelegate (Fixed 200px Left Sidebar on Window Resize, User-Resizable Divider)

- (BOOL)splitView:(NSSplitView *) __unused splitView canCollapseSubview:(NSView *) __unused subview {
	return NO;
}

- (CGFloat)splitView:(NSSplitView *) __unused splitView constrainMinCoordinate:(CGFloat) __unused proposedMinimumPosition ofSubviewAt:(NSInteger) __unused dividerIndex {
	return kMinSidebarWidth;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat) __unused proposedMaximumPosition ofSubviewAt:(NSInteger) __unused dividerIndex {
	return MAX(kMinSidebarWidth, MIN(kMaxSidebarWidth, NSWidth(splitView.bounds) - 320.0));
}

- (BOOL)splitView:(NSSplitView *) __unused splitView shouldAdjustSizeOfSubview:(NSView *)subview {
	if (subview == _schemaSidebarView) {
		return NO;
	}
	return YES;
}

- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize) __unused oldSize {
	NSRect b = splitView.bounds;
	CGFloat divider = splitView.dividerThickness;
	CGFloat maxLeft = MAX(kMinSidebarWidth, MIN(kMaxSidebarWidth, b.size.width - divider - 320.0));
	CGFloat leftW = MIN(MAX(_schemaSidebarWidth, kMinSidebarWidth), maxLeft);
	CGFloat rightW = MAX(0.0, b.size.width - leftW - divider);

	_schemaSidebarView.frame = NSMakeRect(0.0, 0.0, leftW, b.size.height);
	_canvasContainerView.frame = NSMakeRect(leftW + divider, 0.0, rightW, b.size.height);
	[_canvasView ensureCanvasSizeFitsCards];
}

- (void)splitViewDidResizeSubviews:(NSNotification *) __unused notification {
	CGFloat currentLeftWidth = NSWidth(_schemaSidebarView.frame);
	if (currentLeftWidth >= kMinSidebarWidth - 1.0 && currentLeftWidth <= kMaxSidebarWidth + 1.0) {
		_schemaSidebarWidth = currentLeftWidth;
	}
	[_canvasView ensureCanvasSizeFitsCards];
}

#pragma mark - Topological Graph & Reloading Model

- (void)computeTopologicalOrder:(NSArray<NSNumber *> * __autoreleasing *)orderedOut
				   rootTableIDs:(NSSet<NSNumber *> * __autoreleasing *)rootsOut {
	// Matches MADQueryVisualizationModel + MTGraph+RptqQuery on iPad
	MTGraph *graph = [[MTGraph alloc] init];
	for (RptqQueryTable *qt in _queryTables) {
		[graph addVertexWithObject:@(qt.identifier)];
	}
	NSMutableSet<NSNumber *> *rightHandTableIDs = [NSMutableSet set];
	for (RptqQueryLinks *link in _queryLinks) {
		int64_t leftTableID = link.hasLeftField.inQueryTable.identifier;
		int64_t rightTableID = link.hasRightField.inQueryTable.identifier;
		if (leftTableID != 0 && rightTableID != 0) {
			[rightHandTableIDs addObject:@(rightTableID)];
			MTVertex *vOrigin = [graph vertexForObject:@(leftTableID)];
			MTVertex *vDest = [graph vertexForObject:@(rightTableID)];
			if (vOrigin != nil && vDest != nil) {
				[graph addEdgeWithOrigin:vOrigin destination:vDest object:@(link.identifier) andWeight:@(1)];
			}
		}
	}

	NSError *sortError = nil;
	BOOL isDAG = YES;
	MTLinkedList *sortedList = [graph topologicalSortWithError:&sortError isDirectedAcyclicGraph:&isDAG];

	NSMutableArray<NSNumber *> *ordered = [NSMutableArray arrayWithCapacity:_queryTables.count];
	NSMutableSet<NSNumber *> *seen = [NSMutableSet setWithCapacity:_queryTables.count];
	if (sortedList != nil && sortError == nil) {
		for (MTPair *pair in sortedList) {
			MTVertex *v = pair.former;
			if ([v.object isKindOfClass:[NSNumber class]]) {
				NSNumber *tid = (NSNumber *)v.object;
				if (![seen containsObject:tid]) {
					[ordered addObject:tid];
					[seen addObject:tid];
				}
			}
		}
	}
	for (RptqQueryTable *qt in _queryTables) {
		NSNumber *tid = @(qt.identifier);
		if (![seen containsObject:tid]) {
			[ordered addObject:tid];
			[seen addObject:tid];
		}
	}

	NSMutableSet<NSNumber *> *roots = [NSMutableSet set];
	for (NSNumber *tid in ordered) {
		if (![rightHandTableIDs containsObject:tid]) {
			[roots addObject:tid];
		}
	}
	if (roots.count == 0 && ordered.count > 0) {
		[roots addObject:ordered.firstObject];
	}

	if (orderedOut) *orderedOut = ordered;
	if (rootsOut) *rootsOut = roots;
}

- (void)reloadFromDocument {
	RptqDatabase *db = _document.rptqDatabase;
	RptqQuery *query = _document.rptqQuery;

	NSSortDescriptor *byName = [NSSortDescriptor sortDescriptorWithKey:@"name"
															 ascending:YES
															  selector:@selector(localizedCaseInsensitiveCompare:)];
	_schemaTables = [db.hasTables sortedArrayUsingDescriptors:@[byName]] ?: @[];

	NSSortDescriptor *byAlias = [NSSortDescriptor sortDescriptorWithKey:@"alias"
															  ascending:YES
															   selector:@selector(localizedCaseInsensitiveCompare:)];
	NSSortDescriptor *byDrop = [NSSortDescriptor sortDescriptorWithKey:@"dropIndex" ascending:YES];
	_queryTables = [query.hasQueryTables sortedArrayUsingDescriptors:@[byAlias, byDrop]] ?: @[];

	NSMutableArray<RptqQueryField *> *fields = [[NSMutableArray alloc] init];
	for (RptqQueryTable *qt in _queryTables) {
		NSSortDescriptor *fSort = [NSSortDescriptor sortDescriptorWithKey:@"databaseSchemaField.name"
																ascending:YES
																 selector:@selector(localizedCaseInsensitiveCompare:)];
		NSArray<RptqQueryField *> *sorted = [qt.hasQueryFields sortedArrayUsingDescriptors:@[fSort]] ?: @[];
		[fields addObjectsFromArray:sorted];
	}
	_queryFields = fields;

	NSSortDescriptor *byId = [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES];
	_queryLinks = [query.hasQueryLinks sortedArrayUsingDescriptors:@[byId]] ?: @[];
	_queryPredicates = [query.hasQueryPredicate sortedArrayUsingDescriptors:@[byId]] ?: @[];
	_queryGroups = [query sortedQueryGroups] ?: @[];

	[_schemaTablesTable reloadData];

	NSArray<NSNumber *> *topoOrder = nil;
	NSSet<NSNumber *> *rootTableIDs = nil;
	[self computeTopologicalOrder:&topoOrder rootTableIDs:&rootTableIDs];

	// Order _queryTables by topological order for deterministic canvas layout
	NSMutableDictionary<NSNumber *, RptqQueryTable *> *qtByID = [NSMutableDictionary dictionaryWithCapacity:_queryTables.count];
	for (RptqQueryTable *qt in _queryTables) {
		qtByID[@(qt.identifier)] = qt;
	}
	NSMutableArray<RptqQueryTable *> *topoTables = [NSMutableArray arrayWithCapacity:_queryTables.count];
	for (NSNumber *tid in topoOrder) {
		RptqQueryTable *qt = qtByID[tid];
		if (qt != nil) [topoTables addObject:qt];
	}

	[_canvasView rebuildCanvasWithTables:topoTables links:_queryLinks rootTableID:rootTableIDs];

	// Update top bar button badges
	_filtersButton.title = _queryPredicates.count > 0
		? [NSString stringWithFormat:@"Filters (%lu)", (unsigned long)_queryPredicates.count]
		: @"Filters (WHERE)";
	_groupsButton.title = _queryGroups.count > 0
		? [NSString stringWithFormat:@"Groupings (%lu)", (unsigned long)_queryGroups.count]
		: @"Groupings (GROUP BY)";

	[self refreshClausePopoverControls];
	[self syncSQLFromVisualQuery:nil];
}

#pragma mark - Field State Queries

- (BOOL)isQueryFieldLinked:(RptqQueryField *)field {
	if (field == nil) return NO;
	for (RptqQueryLinks *link in _queryLinks) {
		if (link.hasLeftField.identifier == field.identifier ||
			link.hasRightField.identifier == field.identifier) {
			return YES;
		}
	}
	return NO;
}

- (BOOL)isQueryFieldGrouped:(RptqQueryField *)field {
	if (field == nil) return NO;
	for (RptqQueryGroup *grp in _queryGroups) {
		if (grp.hasField.identifier == field.identifier) {
			return YES;
		}
	}
	return NO;
}

- (BOOL)isQueryFieldFiltered:(RptqQueryField *)field {
	if (field == nil) return NO;
	for (RptqQueryPredicate *pred in _queryPredicates) {
		if (pred.hasLeftField.identifier == field.identifier ||
			pred.hasRightField.identifier == field.identifier) {
			return YES;
		}
	}
	return NO;
}

#pragma mark - Adding & Removing Tables (Double-Click Schema Table -> Floating Table Card)

- (void)handleDoubleClickSchemaTable:(id) __unused sender {
	NSInteger row = _schemaTablesTable.clickedRow;
	if (row < 0) row = _schemaTablesTable.selectedRow;
	if (row < 0 || (NSUInteger)row >= _schemaTables.count) return;
	[self addSchemaTableToQuery:_schemaTables[(NSUInteger)row]];
}

- (void)addSelectedSchemaTable:(id) __unused sender {
	NSInteger row = _schemaTablesTable.selectedRow;
	if (row < 0 && _schemaTables.count > 0) row = 0;
	if (row < 0 || (NSUInteger)row >= _schemaTables.count) return;
	[self addSchemaTableToQuery:_schemaTables[(NSUInteger)row]];
}

- (nullable RptqQueryTable *)addSchemaTableToQuery:(RptqDatabaseSchemaTable *)schemaTable {
	if (schemaTable == nil) return nil;
	RptqDatabase *db = _document.rptqDatabase;
	RptqQuery *query = _document.rptqQuery;
	RptqStoreContext *ctx = _document.managedObjectContext;
	if (db == nil || query == nil || ctx == nil) return nil;

	// Create RptqQueryTable AND populate all RptqQueryField children (matches MADQueryViewController+BuilderDelegates.m:421-440)
	RptqQueryTable *newQueryTable = [RptqQueryTable newQueryTableForSchemaTable:schemaTable
																	   database:db
														forManagedObjectContext:ctx];
	NSMutableSet<RptqQueryField *> *newQueryFields = [[NSMutableSet alloc] initWithCapacity:schemaTable.hasFields.count];
	for (RptqDatabaseSchemaField *schemaField in schemaTable.hasFields) {
		RptqQueryField *qf = [RptqQueryField newQueryField:ctx];
		qf.inQueryTable = newQueryTable;
		qf.databaseSchemaField = schemaField;
		[newQueryFields addObject:qf];
	}
	newQueryTable.hasQueryFields = newQueryFields;
	[query addHasQueryTablesObject:newQueryTable];

	[_document notifyDocumentMutated];
	return newQueryTable;
}

- (void)removeQueryTable:(RptqQueryTable *)qt {
	if (qt == nil) return;
	RptqStoreContext *ctx = _document.managedObjectContext;
	RptqQuery *query = _document.rptqQuery;
	if (ctx == nil || query == nil) return;

	[self dismissActiveLinkPopover];

	[_document.headlessDocument deleteDatafieldsRelatedToTable:qt.identifier inContent:ctx];
	[_document.headlessDocument deleteAggregateFieldRelatedToTable:qt.identifier inContent:ctx];

	for (RptqQueryGroup *grp in [query.hasQueryGroups copy]) {
		if (grp.hasField.inQueryTable.identifier == qt.identifier) {
			[_document.headlessDocument removeGroupWitObjectID:grp.identifier fromManagedObjectContext:ctx];
		}
	}
	for (RptqQueryLinks *link in [query.hasQueryLinks copy]) {
		if ([link isConnectedToTable:qt]) {
			if (_canvasView.selectedLinkID == link.identifier) {
				_canvasView.selectedLinkID = 0;
			}
			[query removeHasQueryLinksObject:link];
			[ctx deleteObject:link error:NULL];
		}
	}
	for (RptqQueryPredicate *pred in [query.hasQueryPredicate copy]) {
		if (pred.hasLeftField.inQueryTable.identifier == qt.identifier ||
			pred.hasRightField.inQueryTable.identifier == qt.identifier) {
			[query removeHasQueryPredicateObject:pred];
			[ctx deleteObject:pred error:NULL];
		}
	}
	for (RptqQueryField *qf in [qt.hasQueryFields copy]) {
		[ctx deleteObject:qf error:NULL];
	}
	[_canvasView.cachedFramesByTableID removeObjectForKey:@(qt.identifier)];
	[query removeHasQueryTablesObject:qt];
	[ctx deleteObject:qt error:NULL];
	[_document notifyDocumentMutated];
}

- (void)autoArrangeTablesAction:(id) __unused sender {
	NSArray<NSNumber *> *topoOrder = nil;
	NSSet<NSNumber *> *rootTableIDs = nil;
	[self computeTopologicalOrder:&topoOrder rootTableIDs:&rootTableIDs];
	[_canvasView autoArrangeCardsWithTopologicalOrder:topoOrder rootTableIDs:rootTableIDs];
}

#pragma mark - Connecting Fields & Modifying Link Types

- (nullable RptqQueryLinks *)connectQueryField:(RptqQueryField *)leftField
								  toQueryField:(RptqQueryField *)rightField {
	if (leftField == nil || rightField == nil) return nil;
	if (leftField.inQueryTable == nil || rightField.inQueryTable == nil) return nil;
	if (leftField.inQueryTable.identifier == rightField.inQueryTable.identifier) return nil;

	RptqQuery *query = _document.rptqQuery;
	RptqStoreContext *ctx = _document.managedObjectContext;
	if (query == nil || ctx == nil) return nil;

	// If a link between these exact two fields already exists, return it
	for (RptqQueryLinks *existing in query.hasQueryLinks) {
		if ((existing.hasLeftField.identifier == leftField.identifier && existing.hasRightField.identifier == rightField.identifier) ||
			(existing.hasLeftField.identifier == rightField.identifier && existing.hasRightField.identifier == leftField.identifier)) {
			return existing;
		}
	}

	// Default join type is Left Outer Join (MADLinkTypeLeftOuterJoin), matching iPad MADQueryLinkBuilderController
	RptqQueryLinks *link = [RptqQueryLinks newQueryLinksWithLeftField:leftField
														   rightField:rightField
															 joinType:MADLinkTypeLeftOuterJoin
												 managedObjectContext:ctx];
	[query addHasQueryLinksObject:link];
	_canvasView.selectedLinkID = link.identifier;
	[_document notifyDocumentMutated];
	return link;
}

- (void)updateQueryLink:(RptqQueryLinks *)link joinType:(MADLinkType)joinType {
	if (link == nil) return;
	link.type = joinType;
	[_document notifyDocumentMutated];
}

- (void)swapQueryLinkDirection:(RptqQueryLinks *)link {
	if (link == nil) return;
	RptqQueryField *oldLeft = link.hasLeftField;
	RptqQueryField *oldRight = link.hasRightField;
	if (oldLeft == nil || oldRight == nil) return;

	link.hasLeftField = oldRight;
	link.hasRightField = oldLeft;
	link.tableLeftID = oldRight.inQueryTable.alias.copy;
	link.fieldLeftID = oldRight.databaseSchemaField.name.copy;
	link.tableRightID = oldLeft.inQueryTable.alias.copy;
	link.fieldRightID = oldLeft.databaseSchemaField.name.copy;
	[_document notifyDocumentMutated];
}

- (void)deleteQueryLink:(RptqQueryLinks *)link {
	if (link == nil) return;
	[self dismissActiveLinkPopover];
	if (_canvasView.selectedLinkID == link.identifier) {
		_canvasView.selectedLinkID = 0;
	}
	[_document.rptqQuery removeHasQueryLinksObject:link];
	[_document.managedObjectContext deleteObject:link error:NULL];
	[_document notifyDocumentMutated];
}

- (void) dismissActiveLinkPopover {
	if (_activeLinkPopover.isShown) {
		[_activeLinkPopover close];
	}
	_activeLinkPopover = nil;
}

- (NSArray<NSNumber *> *)supportedJoinTypesForCurrentDatabase {
	// Matches MADQueryAddLinkJoinTypeController.m driver rules, with Left Outer Join first
	NSString *driverID = _document.rptqDatabase.ownedByUser.driverID ?: @"";
	BOOL isMySQL = [driverID isEqualToString:[MADDatabaseConnection Identifier:MADDatabaseTypeMySQL]];
	BOOL isTDS = [driverID isEqualToString:[MADDatabaseConnection Identifier:MADDatabaseTypeTDS]];

	NSMutableArray<NSNumber *> *types = [NSMutableArray arrayWithObjects:
		@(MADLinkTypeLeftOuterJoin),
		@(MADLinkTypeInnerJoin),
		@(MADLinkTypeRightOuterJoin),
		nil];
	if (!isMySQL) {
		[types addObject:@(MADLinkTypeFullOuterJoin)];
	}
	[types addObject:@(MADLinkTypeEquiJoin)];
	if (!isTDS) {
		[types addObject:@(MADLinkTypeNaturalJoin)];
	}
	[types addObject:@(MADLinkTypeCrossJoin)];
	return types;
}

- (void)selectQueryLink:(nullable RptqQueryLinks *)link showPopover:(BOOL)showPopover {
	[self dismissActiveLinkPopover];
	_canvasView.selectedLinkID = (link != nil) ? link.identifier : 0;
	[_canvasView.linksOverlayView setNeedsDisplay:YES];

	if (link == nil || !showPopover || _canvasView.window == nil) {
		return;
	}

	MADMacQueryLinkGeometry *targetGeom = nil;
	for (MADMacQueryLinkGeometry *g in [_canvasView computedLinkGeometries]) {
		if (g.link.identifier == link.identifier) {
			targetGeom = g;
			break;
		}
	}
	if (targetGeom == nil) return;

	NSViewController *vc = [[NSViewController alloc] initWithNibName:nil bundle:nil];
	NSView *popView = [[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 290.0, 142.0)];

	NSString *leftDesc = [NSString stringWithFormat:@"%@.%@",
						  link.hasLeftField.inQueryTable.alias ?: link.tableLeftID ?: @"",
						  link.hasLeftField.databaseSchemaField.name ?: link.fieldLeftID ?: @""];
	NSString *rightDesc = [NSString stringWithFormat:@"%@.%@",
						   link.hasRightField.inQueryTable.alias ?: link.tableRightID ?: @"",
						   link.hasRightField.databaseSchemaField.name ?: link.fieldRightID ?: @""];

	NSTextField *titleLbl = [NSTextField labelWithString:@"Table Join Relationship"];
	titleLbl.font = [NSFont boldSystemFontOfSize:12.5];

	NSTextField *fieldsLbl = [NSTextField labelWithString:[NSString stringWithFormat:@"%@  →  %@", leftDesc, rightDesc]];
	fieldsLbl.font = [NSFont monospacedSystemFontOfSize:11.0 weight:NSFontWeightMedium];
	fieldsLbl.textColor = [NSColor secondaryLabelColor];
	fieldsLbl.lineBreakMode = NSLineBreakByTruncatingMiddle;

	NSTextField *typeLbl = [NSTextField labelWithString:@"Join Type:"];
	typeLbl.font = [NSFont systemFontOfSize:12.0];

	NSPopUpButton *joinPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0.0, 0.0, 180.0, 24.0) pullsDown:NO];
	NSArray<NSNumber *> *supportedTypes = [self supportedJoinTypesForCurrentDatabase];
	NSInteger selectedIdx = 0;
	for (NSUInteger i = 0; i < supportedTypes.count; i++) {
		MADLinkType t = (MADLinkType)supportedTypes[i].shortValue;
		NSString *name = [RptqQueryLinks newLocalizedNameForLinkType:t] ?: @"Left Outer Join";
		[joinPopup addItemWithTitle:name];
		joinPopup.lastItem.tag = t;
		joinPopup.lastItem.representedObject = link;
		if (t == (MADLinkType)link.type) {
			selectedIdx = (NSInteger)i;
		}
	}
	[joinPopup selectItemAtIndex:selectedIdx];
	joinPopup.target = self;
	joinPopup.action = @selector(handleLinkPopoverJoinTypeChanged:);

	NSStackView *typeRow = [NSStackView stackViewWithViews:@[typeLbl, joinPopup]];
	typeRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	typeRow.spacing = 8.0;

	NSButton *swapBtn = [NSButton buttonWithTitle:@"⇄ Swap Direction"
										   target:self
										   action:@selector(handleLinkPopoverSwap:)];
	swapBtn.controlSize = NSControlSizeSmall;
	swapBtn.tag = (NSInteger)link.identifier;

	NSButton *deleteBtn = [NSButton buttonWithTitle:@"Delete Join"
											 target:self
											 action:@selector(handleLinkPopoverDelete:)];
	deleteBtn.controlSize = NSControlSizeSmall;
	deleteBtn.bezelColor = [NSColor systemRedColor];
	deleteBtn.tag = (NSInteger)link.identifier;

	NSStackView *btnRow = [NSStackView stackViewWithViews:@[swapBtn, deleteBtn]];
	btnRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	btnRow.spacing = 10.0;

	NSStackView *vStack = [NSStackView stackViewWithViews:@[titleLbl, fieldsLbl, typeRow, btnRow]];
	vStack.orientation = NSUserInterfaceLayoutOrientationVertical;
	vStack.alignment = NSLayoutAttributeLeading;
	vStack.spacing = 10.0;
	vStack.translatesAutoresizingMaskIntoConstraints = NO;
	[popView addSubview:vStack];

	[NSLayoutConstraint activateConstraints:@[
		[vStack.topAnchor constraintEqualToAnchor:popView.topAnchor constant:12.0],
		[vStack.leadingAnchor constraintEqualToAnchor:popView.leadingAnchor constant:14.0],
		[vStack.trailingAnchor constraintEqualToAnchor:popView.trailingAnchor constant:-14.0],
	]];

	vc.view = popView;
	_activeLinkPopover = [[NSPopover alloc] init];
	_activeLinkPopover.contentViewController = vc;
	_activeLinkPopover.behavior = NSPopoverBehaviorTransient;
	[_activeLinkPopover showRelativeToRect:targetGeom.badgeRect
									ofView:_canvasView.linksOverlayView
							 preferredEdge:NSRectEdgeMaxY];
}

- (void)handleLinkPopoverJoinTypeChanged:(NSPopUpButton *)sender {
	NSMenuItem *item = sender.selectedItem;
	RptqQueryLinks *link = item.representedObject;
	if ([link isKindOfClass:[RptqQueryLinks class]]) {
		[self updateQueryLink:link joinType:(MADLinkType)item.tag];
	}
}

- (void)handleLinkPopoverSwap:(NSButton *)sender {
	int64_t linkID = sender.tag;
	for (RptqQueryLinks *link in _queryLinks) {
		if (link.identifier == linkID) {
			[self dismissActiveLinkPopover];
			[self swapQueryLinkDirection:link];
			break;
		}
	}
}

- (void)handleLinkPopoverDelete:(NSButton *)sender {
	int64_t linkID = sender.tag;
	for (RptqQueryLinks *link in _queryLinks) {
		if (link.identifier == linkID) {
			[self deleteQueryLink:link];
			break;
		}
	}
}

#pragma mark - Context Menus for Links & Fields

- (NSMenu *)contextMenuForQueryLink:(RptqQueryLinks *)link {
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Join Link"];
	for (NSNumber *typeNum in [self supportedJoinTypesForCurrentDatabase]) {
		MADLinkType t = (MADLinkType)typeNum.shortValue;
		NSString *title = [RptqQueryLinks newLocalizedNameForLinkType:t] ?: @"Left Outer Join";
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title
													  action:@selector(handleContextMenuSetJoinType:)
											   keyEquivalent:@""];
		item.target = self;
		item.tag = t;
		item.representedObject = link;
		item.state = ((MADLinkType)link.type == t) ? NSControlStateValueOn : NSControlStateValueOff;
		[menu addItem:item];
	}
	[menu addItem:[NSMenuItem separatorItem]];

	NSMenuItem *swapItem = [[NSMenuItem alloc] initWithTitle:@"Swap Left / Right Direction"
													  action:@selector(handleContextMenuSwapLink:)
											   keyEquivalent:@""];
	swapItem.target = self;
	swapItem.representedObject = link;
	[menu addItem:swapItem];

	NSMenuItem *delItem = [[NSMenuItem alloc] initWithTitle:@"Delete Join Link"
													 action:@selector(handleContextMenuDeleteLink:)
											  keyEquivalent:@""];
	delItem.target = self;
	delItem.representedObject = link;
	[menu addItem:delItem];
	return menu;
}

- (void)handleContextMenuSetJoinType:(NSMenuItem *)sender {
	RptqQueryLinks *link = sender.representedObject;
	if ([link isKindOfClass:[RptqQueryLinks class]]) {
		[self updateQueryLink:link joinType:(MADLinkType)sender.tag];
	}
}

- (void)handleContextMenuSwapLink:(NSMenuItem *)sender {
	RptqQueryLinks *link = sender.representedObject;
	if ([link isKindOfClass:[RptqQueryLinks class]]) {
		[self swapQueryLinkDirection:link];
	}
}

- (void)handleContextMenuDeleteLink:(NSMenuItem *)sender {
	RptqQueryLinks *link = sender.representedObject;
	if ([link isKindOfClass:[RptqQueryLinks class]]) {
		[self deleteQueryLink:link];
	}
}

- (NSMenu *)contextMenuForQueryField:(RptqQueryField *)field inCard:(MADMacQueryTableCardView *)card {
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Field"];
	NSString *fieldTitle = [NSString stringWithFormat:@"%@.%@",
							card.queryTable.alias ?: card.queryTable.databaseSchemaTable.name ?: @"",
							field.databaseSchemaField.name ?: @""];

	// Submenu to create a Left Outer Join to a field in another table
	if (_queryTables.count > 1) {
		NSMenuItem *connectMenuParent = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Link %@ (Left Outer Join) to", fieldTitle]
																   action:nil
															keyEquivalent:@""];
		NSMenu *connectSubmenu = [[NSMenu alloc] initWithTitle:@"Link to Field"];
		for (RptqQueryTable *otherTable in _queryTables) {
			if (otherTable.identifier == card.queryTable.identifier) continue;
			MADMacQueryTableCardView *otherCard = _canvasView.cardsByTableID[@(otherTable.identifier)];
			NSArray<RptqQueryField *> *otherFields = otherCard ? otherCard.orderedFields : [otherTable.hasQueryFields allObjects];
			for (RptqQueryField *otherField in otherFields) {
				NSString *targetLabel = [NSString stringWithFormat:@"%@.%@",
										 otherTable.alias ?: otherTable.databaseSchemaTable.name ?: @"",
										 otherField.databaseSchemaField.name ?: @""];
				NSMenuItem *targetItem = [[NSMenuItem alloc] initWithTitle:targetLabel
																	action:@selector(handleContextMenuConnectFields:)
															 keyEquivalent:@""];
				targetItem.target = self;
				targetItem.representedObject = @[field, otherField];
				[connectSubmenu addItem:targetItem];
			}
		}
		connectMenuParent.submenu = connectSubmenu;
		[menu addItem:connectMenuParent];
		[menu addItem:[NSMenuItem separatorItem]];
	}

	NSMenuItem *grpAsc = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Group By %@ (Ascending)", fieldTitle]
													action:@selector(handleContextMenuGroupFieldAsc:)
											 keyEquivalent:@""];
	grpAsc.target = self;
	grpAsc.representedObject = field;
	[menu addItem:grpAsc];

	NSMenuItem *grpDesc = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Group By %@ (Descending)", fieldTitle]
													 action:@selector(handleContextMenuGroupFieldDesc:)
											  keyEquivalent:@""];
	grpDesc.target = self;
	grpDesc.representedObject = field;
	[menu addItem:grpDesc];

	[menu addItem:[NSMenuItem separatorItem]];
	NSMenuItem *remTable = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Remove Table '%@' from Query", card.queryTable.alias ?: @""]
													  action:@selector(handleContextMenuRemoveTable:)
											   keyEquivalent:@""];
	remTable.target = self;
	remTable.representedObject = card.queryTable;
	[menu addItem:remTable];
	return menu;
}

- (void)handleContextMenuConnectFields:(NSMenuItem *)sender {
	NSArray *pair = sender.representedObject;
	if ([pair isKindOfClass:[NSArray class]] && pair.count == 2) {
		[self connectQueryField:pair[0] toQueryField:pair[1]];
	}
}

- (void)handleContextMenuGroupFieldAsc:(NSMenuItem *)sender {
	RptqQueryField *qf = sender.representedObject;
	if ([qf isKindOfClass:[RptqQueryField class]]) {
		[_document.headlessDocument addQueryGroupWithQueryField:qf.identifier andSortOrder:MADSortOrderAccending];
		[_document notifyDocumentMutated];
	}
}

- (void)handleContextMenuGroupFieldDesc:(NSMenuItem *)sender {
	RptqQueryField *qf = sender.representedObject;
	if ([qf isKindOfClass:[RptqQueryField class]]) {
		[_document.headlessDocument addQueryGroupWithQueryField:qf.identifier andSortOrder:MADSortOrderDecending];
		[_document notifyDocumentMutated];
	}
}

- (void)handleContextMenuRemoveTable:(NSMenuItem *)sender {
	RptqQueryTable *qt = sender.representedObject;
	if ([qt isKindOfClass:[RptqQueryTable class]]) {
		[self removeQueryTable:qt];
	}
}

#pragma mark - Filters (WHERE) & Groupings (GROUP BY) Popovers

- (void)refreshClausePopoverControls {
	if (_predicateFieldPopup != nil) {
		[_predicateFieldPopup removeAllItems];
		for (RptqQueryField *qf in _queryFields) {
			NSString *label = [NSString stringWithFormat:@"%@.%@",
							   qf.inQueryTable.alias ?: qf.inQueryTable.databaseSchemaTable.name ?: @"",
							   qf.databaseSchemaField.name ?: @""];
			[_predicateFieldPopup addItemWithTitle:label];
			_predicateFieldPopup.lastItem.tag = (NSInteger)qf.identifier;
		}
	}
	if (_groupFieldPopup != nil) {
		[_groupFieldPopup removeAllItems];
		for (RptqQueryField *qf in _queryFields) {
			NSString *label = [NSString stringWithFormat:@"%@.%@",
							   qf.inQueryTable.alias ?: qf.inQueryTable.databaseSchemaTable.name ?: @"",
							   qf.databaseSchemaField.name ?: @""];
			[_groupFieldPopup addItemWithTitle:label];
			_groupFieldPopup.lastItem.tag = (NSInteger)qf.identifier;
		}
	}
	[_predicatesTable reloadData];
	[_groupsTable reloadData];
}

- (void)toggleFiltersPopover:(NSButton *)sender {
	if (_filtersPopover.isShown) {
		[_filtersPopover close];
		return;
	}
	if (_filtersPopover == nil) {
		NSViewController *vc = [[NSViewController alloc] initWithNibName:nil bundle:nil];
		NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 480.0, 220.0)];

		_predicateFieldPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0.0, 0.0, 160.0, 24.0) pullsDown:NO];
		_predicateOperatorPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0.0, 0.0, 68.0, 24.0) pullsDown:NO];
		[_predicateOperatorPopup addItemsWithTitles:@[@"=", @"!=", @"<", @"<=", @">", @">="]];
		_predicateValueField = [[NSTextField alloc] initWithFrame:NSMakeRect(0.0, 0.0, 120.0, 24.0)];
		_predicateValueField.placeholderString = @"Value";
		[_predicateValueField.widthAnchor constraintGreaterThanOrEqualToConstant:110.0].active = YES;

		NSButton *addBtn = [NSButton buttonWithTitle:@"+ Add" target:self action:@selector(addPredicateAction:)];
		NSButton *remBtn = [NSButton buttonWithTitle:@"- Remove" target:self action:@selector(removePredicateAction:)];

		NSStackView *topRow = [NSStackView stackViewWithViews:@[_predicateFieldPopup, _predicateOperatorPopup, _predicateValueField, addBtn, remBtn]];
		topRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
		topRow.spacing = 6.0;
		topRow.translatesAutoresizingMaskIntoConstraints = NO;

		_predicatesTable = [[NSTableView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 456.0, 150.0)];
		_predicatesTable.usesAlternatingRowBackgroundColors = YES;
		_predicatesTable.rowHeight = 22.0;
		_predicatesTable.delegate = self;
		_predicatesTable.dataSource = self;
		NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:@"pred"];
		col.title = @"Active WHERE Filters";
		col.width = 440.0;
		[_predicatesTable addTableColumn:col];

		NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 456.0, 150.0)];
		scroll.hasVerticalScroller = YES;
		scroll.borderType = NSBezelBorder;
		scroll.documentView = _predicatesTable;
		scroll.translatesAutoresizingMaskIntoConstraints = NO;

		[view addSubview:topRow];
		[view addSubview:scroll];
		[NSLayoutConstraint activateConstraints:@[
			[topRow.topAnchor constraintEqualToAnchor:view.topAnchor constant:10.0],
			[topRow.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:10.0],
			[topRow.trailingAnchor constraintLessThanOrEqualToAnchor:view.trailingAnchor constant:-10.0],
			[scroll.topAnchor constraintEqualToAnchor:topRow.bottomAnchor constant:8.0],
			[scroll.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:10.0],
			[scroll.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-10.0],
			[scroll.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-10.0],
		]];
		vc.view = view;
		_filtersPopover = [[NSPopover alloc] init];
		_filtersPopover.contentViewController = vc;
		_filtersPopover.behavior = NSPopoverBehaviorTransient;
	}
	[self refreshClausePopoverControls];
	[_filtersPopover showRelativeToRect:sender.bounds ofView:sender preferredEdge:NSRectEdgeMaxY];
}

- (void)toggleGroupsPopover:(NSButton *)sender {
	if (_groupsPopover.isShown) {
		[_groupsPopover close];
		return;
	}
	if (_groupsPopover == nil) {
		NSViewController *vc = [[NSViewController alloc] initWithNibName:nil bundle:nil];
		NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 440.0, 220.0)];

		_groupFieldPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0.0, 0.0, 180.0, 24.0) pullsDown:NO];
		_groupSortPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0.0, 0.0, 110.0, 24.0) pullsDown:NO];
		[_groupSortPopup addItemsWithTitles:@[@"Ascending", @"Descending"]];

		NSButton *addBtn = [NSButton buttonWithTitle:@"+ Add Group" target:self action:@selector(addGroupAction:)];
		NSButton *remBtn = [NSButton buttonWithTitle:@"- Remove" target:self action:@selector(removeSelectedGroupAction:)];

		NSStackView *topRow = [NSStackView stackViewWithViews:@[_groupFieldPopup, _groupSortPopup, addBtn, remBtn]];
		topRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
		topRow.spacing = 6.0;
		topRow.translatesAutoresizingMaskIntoConstraints = NO;

		_groupsTable = [[NSTableView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 416.0, 150.0)];
		_groupsTable.usesAlternatingRowBackgroundColors = YES;
		_groupsTable.rowHeight = 22.0;
		_groupsTable.delegate = self;
		_groupsTable.dataSource = self;
		NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:@"group"];
		col.title = @"Report Grouping Levels (GROUP BY)";
		col.width = 400.0;
		[_groupsTable addTableColumn:col];

		NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 416.0, 150.0)];
		scroll.hasVerticalScroller = YES;
		scroll.borderType = NSBezelBorder;
		scroll.documentView = _groupsTable;
		scroll.translatesAutoresizingMaskIntoConstraints = NO;

		[view addSubview:topRow];
		[view addSubview:scroll];
		[NSLayoutConstraint activateConstraints:@[
			[topRow.topAnchor constraintEqualToAnchor:view.topAnchor constant:10.0],
			[topRow.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:10.0],
			[topRow.trailingAnchor constraintLessThanOrEqualToAnchor:view.trailingAnchor constant:-10.0],
			[scroll.topAnchor constraintEqualToAnchor:topRow.bottomAnchor constant:8.0],
			[scroll.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:10.0],
			[scroll.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-10.0],
			[scroll.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-10.0],
		]];
		vc.view = view;
		_groupsPopover = [[NSPopover alloc] init];
		_groupsPopover.contentViewController = vc;
		_groupsPopover.behavior = NSPopoverBehaviorTransient;
	}
	[self refreshClausePopoverControls];
	[_groupsPopover showRelativeToRect:sender.bounds ofView:sender preferredEdge:NSRectEdgeMaxY];
}

- (void)addPredicateAction:(id) __unused sender {
	NSMenuItem *fieldItem = _predicateFieldPopup.selectedItem;
	NSString *value = _predicateValueField.stringValue ?: @"";
	if (fieldItem == nil || value.length == 0) return;

	MADPredicateOperator op = MADPredicateOperatorEqual;
	switch (_predicateOperatorPopup.indexOfSelectedItem) {
		case 1: op = MADPredicateOperatorNotEqual; break;
		case 2: op = MADPredicateOperatorLessThan; break;
		case 3: op = MADPredicateOperatorLessThanOrEqualTo; break;
		case 4: op = MADPredicateOperatorGreaterThan; break;
		case 5: op = MADPredicateOperatorGreaterThanOrEqualTo; break;
		default: op = MADPredicateOperatorEqual; break;
	}

	NSError *err = nil;
	RptqQueryPredicate *pred = [RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID:fieldItem.tag
																		 comparsonOperator:op
																			 andRightValue:value
																   forManagedObjectContext:_document.managedObjectContext
																					 error:&err];
	if (pred != nil && err == nil) {
		[_document.rptqQuery addHasQueryPredicateObject:pred];
		_predicateValueField.stringValue = @"";
		[_document notifyDocumentMutated];
	}
}

- (void)removePredicateAction:(id) __unused sender {
	NSInteger row = _predicatesTable.selectedRow;
	if (row < 0 || (NSUInteger)row >= _queryPredicates.count) return;
	RptqQueryPredicate *pred = _queryPredicates[(NSUInteger)row];
	[_document.rptqQuery removeHasQueryPredicateObject:pred];
	[RptqQueryPredicate deletePredicate:pred];
	[_document notifyDocumentMutated];
}

- (void)addGroupAction:(id) __unused sender {
	NSMenuItem *fieldItem = _groupFieldPopup.selectedItem;
	if (fieldItem == nil) return;
	MADSortOrder sort = (_groupSortPopup.indexOfSelectedItem == 1) ? MADSortOrderDecending : MADSortOrderAccending;
	[_document.headlessDocument addQueryGroupWithQueryField:fieldItem.tag andSortOrder:sort];
	[_document notifyDocumentMutated];
}

- (void)removeSelectedGroupAction:(id) __unused sender {
	NSInteger row = _groupsTable.selectedRow;
	if (row < 0 || (NSUInteger)row >= _queryGroups.count) return;
	RptqQueryGroup *group = _queryGroups[(NSUInteger)row];
	[_document.headlessDocument removeGroupWitObjectID:group.identifier
							  fromManagedObjectContext:_document.managedObjectContext];
	[_document notifyDocumentMutated];
}

#pragma mark - SQL Query Mode (Sync, Validate, Compile & Apply)

- (NSString *)generatedSQLString {
	[_document.headlessDocument invalidateQueryAndModelCaches];
	NSError *allFieldsErr = nil;
	NSString *generated = [_document.headlessDocument.mainQuery SQLOnlyActiveFields:NO
															   managedObjectContext:_document.managedObjectContext
																			  error:&allFieldsErr];
	if (generated.length == 0) {
		NSError *activeErr = nil;
		generated = [_document.headlessDocument.mainQuery copySQLWithManagedObjectContext:_document.managedObjectContext
																					error:&activeErr];
	}
	return generated ?: @"";
}

- (void)syncSQLFromVisualQuery:(id) __unused sender {
	NSString *entered = _document.rptqQuery.sqlSourceText ?: @"";
	_sqlSourceTabControl.hidden = (entered.length == 0);
	NSString *generated = [self generatedSQLString];
	if (_sqlSourceTabControl.selectedSegment == 1 && entered.length > 0) {
		_sqlTextView.string = entered;
	} else if (generated.length > 0) {
		_sqlTextView.string = generated;
	} else if (entered.length > 0) {
		_sqlTextView.string = entered;
	} else {
		_sqlTextView.string = @"";
	}
}

- (void)sqlSourceTabChanged:(NSSegmentedControl *) __unused sender {
	[self syncSQLFromVisualQuery:nil];
}

- (NSDictionary<NSString *, NSArray<NSString *> *> *)schemaDictionaryForParser {
	RptqDatabase *db = _document.rptqDatabase;
	NSMutableDictionary<NSString *, NSArray<NSString *> *> *schemaMap = [[NSMutableDictionary alloc] init];
	for (RptqDatabaseSchemaTable *st in db.hasTables) {
		if (st.name.length == 0) continue;
		NSMutableArray<NSString *> *cols = [[NSMutableArray alloc] init];
		for (RptqDatabaseSchemaField *sf in st.hasFields) {
			if (sf.name.length > 0) [cols addObject:sf.name];
		}
		schemaMap[st.name] = cols;
	}
	return schemaMap;
}

- (void)validateSQLAction:(id) __unused sender {
	NSString *sql = [_sqlTextView.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (sql.length == 0) {
		_sqlStatusLabel.textColor = [NSColor systemRedColor];
		_sqlStatusLabel.stringValue = @"Enter a SELECT statement to validate.";
		return;
	}
	RptqDatabase *db = _document.rptqDatabase;
	NSError *err = nil;
	MADSQLParser *parser = [[MADSQLParser alloc] initWithSQL:sql
								   identifierQuoteCharacters:[MADDatabase identifierQuoteCharacters]
													  schema:[self schemaDictionaryForParser]];
	MADSQLStatement *statement = [parser parseStatement:&err];
	if (statement == nil) {
		_sqlStatusLabel.textColor = [NSColor systemRedColor];
		_sqlStatusLabel.stringValue = [NSString stringWithFormat:@"SQL Parse Error: %@", err.localizedDescription];
		return;
	}
	MADSQLStatementResolver *resolver = [[MADSQLStatementResolver alloc] initWithStatement:statement database:db];
	MADSQLQueryPlan *plan = [resolver resolveWithError:&err];
	if (plan == nil) {
		_sqlStatusLabel.textColor = [NSColor systemRedColor];
		_sqlStatusLabel.stringValue = [NSString stringWithFormat:@"SQL Resolve Error: %@", err.localizedDescription];
		return;
	}
	_sqlStatusLabel.textColor = [NSColor systemGreenColor];
	_sqlStatusLabel.stringValue = [NSString stringWithFormat:@"Valid SQL: %lu table(s), %lu join(s), %lu filter(s), %lu group(s).",
								   (unsigned long)plan.tables.count,
								   (unsigned long)plan.links.count,
								   (unsigned long)plan.predicates.count,
								   (unsigned long)plan.groups.count];
}

- (void)compileAndApplySQL:(id) __unused sender {
	NSString *sql = [_sqlTextView.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (sql.length == 0) return;

	RptqDatabase *db = _document.rptqDatabase;
	RptqQuery *query = _document.rptqQuery;
	RptqStoreContext *ctx = _document.managedObjectContext;
	MADHeadlessDocument *headless = _document.headlessDocument;
	if (db == nil || query == nil || ctx == nil || headless == nil) return;

	NSError *parseError = nil;
	MADSQLParser *parser = [[MADSQLParser alloc] initWithSQL:sql
								   identifierQuoteCharacters:[MADDatabase identifierQuoteCharacters]
													  schema:[self schemaDictionaryForParser]];
	MADSQLStatement *statement = [parser parseStatement:&parseError];
	if (statement == nil) {
		_sqlStatusLabel.textColor = [NSColor systemRedColor];
		_sqlStatusLabel.stringValue = [NSString stringWithFormat:@"SQL Parse Error: %@", parseError.localizedDescription];
		return;
	}

	NSError *resolveError = nil;
	MADSQLStatementResolver *resolver = [[MADSQLStatementResolver alloc] initWithStatement:statement database:db];
	MADSQLQueryPlan *plan = [resolver resolveWithError:&resolveError];
	if (plan == nil) {
		_sqlStatusLabel.textColor = [NSColor systemRedColor];
		_sqlStatusLabel.stringValue = [NSString stringWithFormat:@"SQL Resolve Error: %@", resolveError.localizedDescription];
		return;
	}

	NSError *applyError = nil;
	MADSQLQueryCompiler *compiler = [[MADSQLQueryCompiler alloc] initWithPlan:plan
																	 document:headless
																		query:query
																	  context:ctx];
	if (![compiler applyWithError:&applyError]) {
		_sqlStatusLabel.textColor = [NSColor systemRedColor];
		_sqlStatusLabel.stringValue = [NSString stringWithFormat:@"SQL Apply Error: %@", applyError.localizedDescription];
		return;
	}

	_sqlStatusLabel.textColor = [NSColor systemGreenColor];
	_sqlStatusLabel.stringValue = [NSString stringWithFormat:@"Applied: %lu table(s), %lu join(s), %lu filter(s), %lu group(s).",
								   (unsigned long)plan.tables.count,
								   (unsigned long)plan.links.count,
								   (unsigned long)plan.predicates.count,
								   (unsigned long)plan.groups.count];
	[_document notifyDocumentMutated];
}

#pragma mark - NSTableViewDataSource & Delegate (Schema Table List + Popover Tables)

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	if (tableView == _schemaTablesTable) return (NSInteger)_schemaTables.count;
	if (tableView == _predicatesTable) return (NSInteger)_queryPredicates.count;
	if (tableView == _groupsTable) return (NSInteger)_queryGroups.count;
	return 0;
}

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *) __unused tableColumn row:(NSInteger)row {
	NSString *text = @"";
	BOOL isSchemaInQuery = NO;

	if (tableView == _schemaTablesTable && (NSUInteger)row < _schemaTables.count) {
		RptqDatabaseSchemaTable *st = _schemaTables[(NSUInteger)row];
		NSUInteger inQueryCount = 0;
		for (RptqQueryTable *qt in _queryTables) {
			if (qt.databaseSchemaTable.identifier == st.identifier) {
				inQueryCount++;
			}
		}
		isSchemaInQuery = (inQueryCount > 0);
		if (inQueryCount > 0) {
			text = [NSString stringWithFormat:@"✓ %@ (%lu)", st.name ?: @"", (unsigned long)st.hasFields.count];
		} else {
			text = [NSString stringWithFormat:@"%@ (%lu)", st.name ?: @"", (unsigned long)st.hasFields.count];
		}
	} else if (tableView == _predicatesTable && (NSUInteger)row < _queryPredicates.count) {
		RptqQueryPredicate *pred = _queryPredicates[(NSUInteger)row];
		NSString *lhs = pred.hasLeftField
			? [NSString stringWithFormat:@"%@.%@", pred.hasLeftField.inQueryTable.alias ?: @"", pred.hasLeftField.databaseSchemaField.name ?: @""]
			: (pred.leftFieldID ?: @"");
		NSString *rhs = pred.hasRightField
			? [NSString stringWithFormat:@"%@.%@", pred.hasRightField.inQueryTable.alias ?: @"", pred.hasRightField.databaseSchemaField.name ?: @""]
			: (pred.rightFieldID ?: @"");
		text = [NSString stringWithFormat:@"%@ %@ %@", lhs, [pred symbolForDisplay] ?: @"==", rhs];
	} else if (tableView == _groupsTable && (NSUInteger)row < _queryGroups.count) {
		RptqQueryGroup *grp = _queryGroups[(NSUInteger)row];
		text = [NSString stringWithFormat:@"%ld. %@ (%@)", (long)(row + 1), [grp fieldNameNice] ?: @"", [grp sortDisplayNice] ?: @"ASC"];
	}

	NSTextField *cell = [tableView makeViewWithIdentifier:@"Cell" owner:self];
	if (cell == nil) {
		cell = [NSTextField labelWithString:text];
		cell.identifier = @"Cell";
		cell.lineBreakMode = NSLineBreakByTruncatingTail;
	} else {
		cell.stringValue = text;
	}
	if (tableView == _schemaTablesTable) {
		cell.font = isSchemaInQuery
			? [NSFont systemFontOfSize:12.0 weight:NSFontWeightSemibold]
			: [NSFont systemFontOfSize:12.0 weight:NSFontWeightRegular];
		cell.toolTip = @"Double-click to add table to query";
	} else {
		cell.font = [NSFont systemFontOfSize:12.0];
	}
	return cell;
}

@end
