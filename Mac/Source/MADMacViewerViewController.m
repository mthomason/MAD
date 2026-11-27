//
//  MADMacViewerViewController.m
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMacViewerViewController.h"
#import "MADMacDocument.h"
#import "MADMacWindowController.h"
#import "MADMacConnectionWindowController.h"
#import "MADMacTipBar.h"

#import <MAD/MAD.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseConnectionsPropertiesURLProtocol.h>
#import <MADSqlite3/MADDataTableFast.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <Quartz/Quartz.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

static const CGFloat kViewerTopToolbarHeight = 44.0;
static const CGFloat kViewerBottomStatusBarHeight = 34.0;

/// An SF Symbol image, or an invisible placeholder so the control keeps its geometry if
/// the symbol is unavailable.
static NSImage *MADViewerSymbolImage(NSString *name, NSString * _Nullable description) {
	NSImage *image = [NSImage imageWithSystemSymbolName:name accessibilityDescription:description];
	return image ?: [[NSImage alloc] initWithSize:NSMakeSize(14.0, 14.0)];
}

@interface MADMacViewerViewController () <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, strong, readwrite) NSButton *refreshButton;
@property (nonatomic, strong, readwrite) NSButton *connectionButton;
@property (nonatomic, strong, readwrite) NSButton *exportButton;
@property (nonatomic, strong, readwrite) NSButton *printButton;
@property (nonatomic, strong, readwrite) NSPopUpButton *pageSizePopup;
@property (nonatomic, strong, readwrite) NSPopUpButton *exportFormatPopup;
@property (nonatomic, strong, readwrite) PDFView *pdfView;
@property (nonatomic, strong, readwrite) NSView *statusBarView;
@property (nonatomic, strong, readwrite) NSTextField *statusLabel;
@property (nonatomic, strong, readwrite, nullable) NSError *lastRefreshError;

@property (nonatomic, strong, readwrite) NSTableView *rowGridView;
@property (nonatomic, strong) NSScrollView *rowGridScrollView;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, id> *> *gridRows;

@property (nonatomic, strong) NSProgressIndicator *spinner;
@property (nonatomic, strong) NSTextField *paperStatusLabel;
@property (nonatomic, strong) NSButton *zoomOutButton;
@property (nonatomic, strong) NSButton *zoomLabelButton;
@property (nonatomic, strong) NSButton *zoomInButton;
@property (nonatomic, strong) NSButton *prevPageButton;
@property (nonatomic, strong) NSTextField *pageNumberLabel;
@property (nonatomic, strong) NSButton *nextPageButton;
@property (nonatomic, strong) NSButton *overflowButton;
@property (nonatomic, strong) NSStackView *pageControlsStack;
@property (nonatomic, strong) MADMacTipBar *tipBar;

@property (nonatomic, assign, readwrite) MTPaperType renderedPaperType;
@property (nonatomic, assign, readwrite) CGSize renderedPaperSize;
@property (nonatomic, weak, nullable) NSSavePanel *activeExportSavePanel;
@property (nonatomic, copy) NSArray<Class<MADReportExporting>> *exporterClasses;

@end

@implementation MADMacViewerViewController

+ (NSString *)statusMessageForPageCount:(NSUInteger)pageCount
							   rowCount:(NSUInteger)rowCount {
	NSString *pageText = (pageCount == 1)
		? NSLocalizedString(@"1 page", @"Status line: the rendered report has one page.")
		: [[NSString alloc] initWithFormat:NSLocalizedString(@"%lu pages", @"Status line: the rendered report has several pages. %lu is the count."), (unsigned long)pageCount];
	NSString *rowText = (rowCount == 1)
		? NSLocalizedString(@"1 cached row", @"Status line: the report cached one row.")
		: [[NSString alloc] initWithFormat:NSLocalizedString(@"%lu cached rows", @"Status line: the report cached several rows. %lu is the count."), (unsigned long)rowCount];
	return [[NSString alloc] initWithFormat:NSLocalizedString(@"Rendered %1$@ from %2$@.", @"Status line after rendering. %1$@ is the page count phrase, %2$@ is the cached-row count phrase."), pageText, rowText];
}

+ (NSString *)friendlyTitleForExporterFormat:(NSString *)formatName extension:(NSString *)ext {
	if ([formatName isEqualToString:@"pdf"]) return [[NSString alloc] initWithFormat:NSLocalizedString(@"PDF Document (.%@)", @"Export format menu: PDF. Keep PDF and the file extension. %@ is the extension."), ext];
	if ([formatName isEqualToString:@"html"]) return [[NSString alloc] initWithFormat:NSLocalizedString(@"HTML Page (.%@)", @"Export format menu: one HTML page. Keep HTML and the file extension. %@ is the extension."), ext];
	if ([formatName isEqualToString:@"html-flow"]) return [[NSString alloc] initWithFormat:NSLocalizedString(@"HTML Flow (.%@)", @"Export format menu: flowing HTML. Keep HTML and the file extension. %@ is the extension."), ext];
	if ([formatName isEqualToString:@"csv"]) return [[NSString alloc] initWithFormat:NSLocalizedString(@"CSV Spreadsheet (.%@)", @"Export format menu: CSV. Keep CSV and the file extension. %@ is the extension."), ext];
	if ([formatName isEqualToString:@"json"]) return [[NSString alloc] initWithFormat:NSLocalizedString(@"JSON Data (.%@)", @"Export format menu: JSON data. Keep JSON and the file extension. %@ is the extension."), ext];
	if ([formatName isEqualToString:@"json-report"]) return [[NSString alloc] initWithFormat:NSLocalizedString(@"JSON Full Report (.%@)", @"Export format menu: JSON with layout. Keep JSON and the file extension. %@ is the extension."), ext];
	if ([formatName isEqualToString:@"text"]) return [[NSString alloc] initWithFormat:NSLocalizedString(@"Plain Text (.%@)", @"Export format menu: plain text. %@ is the file extension."), ext];
	return [[NSString alloc] initWithFormat:NSLocalizedString(@"%1$@ (%2$@)", @"Export format menu fallback. %1$@ is the upper-cased format identifier, %2$@ is the file extension."), formatName.uppercaseString, ext];
}

- (instancetype)initWithDocument:(MADMacDocument *)document {
	if (self = [super initWithNibName:nil bundle:nil]) {
		_document = document;
		_exporterClasses = [MADReportExporterRegistry registeredExporterClasses] ?: @[];
		_selectedPaperType = MTPaperTypeLetter;
		_renderedPaperType = MTPaperTypeLetter;
		_renderedPaperSize = [MTPaper sizeForType:MTPaperTypeLetter];
		_zoomScale = 1.0;
		if (document.headlessDocument != nil) {
			[document.headlessDocument setPaperType:MTPaperTypeLetter];
		}
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView {
	NSView *root = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 1180, 740)];
	root.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

	// 1. Top Toolbar: the three primary actions, plus a quiet overflow for the rest.
	NSView *topBar = [[NSView alloc] initWithFrame:NSMakeRect(0, 740 - kViewerTopToolbarHeight, 1180, kViewerTopToolbarHeight)];
	topBar.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
	topBar.wantsLayer = YES;
	topBar.layer.backgroundColor = [NSColor windowBackgroundColor].CGColor;

	NSBox *topSep = [[NSBox alloc] initWithFrame:NSMakeRect(0, 0, 1180, 1)];
	topSep.boxType = NSBoxSeparator;
	topSep.autoresizingMask = NSViewWidthSizable | NSViewMaxYMargin;
	[topBar addSubview:topSep];

	_refreshButton = [NSButton buttonWithTitle:NSLocalizedString(@"Refresh", @"Viewer button that re-runs the query and re-renders the report.")
										target:self
										action:@selector(refreshReportAction:)];
	_refreshButton.image = MADViewerSymbolImage(@"arrow.clockwise", NSLocalizedString(@"Refresh Report", @"Accessibility description for the refresh button icon."));
	_refreshButton.imagePosition = NSImageLeft;
	_refreshButton.bezelStyle = NSBezelStyleRounded;
	_refreshButton.bezelColor = [NSColor controlAccentColor];
	_refreshButton.toolTip = NSLocalizedString(@"Run the query and render the report (⌘R).", @"Tooltip for the viewer refresh button.");
	_refreshButton.accessibilityLabel = NSLocalizedString(@"Refresh Report", @"Accessibility label for the viewer refresh button.");

	_printButton = [NSButton buttonWithTitle:NSLocalizedString(@"Print…", @"Viewer button that prints the rendered report.")
									  target:self
									  action:@selector(printReportAction:)];
	_printButton.image = MADViewerSymbolImage(@"printer", NSLocalizedString(@"Print Report", @"Accessibility description for the print button icon."));
	_printButton.imagePosition = NSImageLeft;
	_printButton.bezelStyle = NSBezelStyleRounded;
	_printButton.toolTip = NSLocalizedString(@"Print the rendered report (⌘P).", @"Tooltip for the viewer print button.");
	_printButton.accessibilityLabel = NSLocalizedString(@"Print Report", @"Accessibility label for the viewer print button.");

	_exportButton = [NSButton buttonWithTitle:NSLocalizedString(@"Export…", @"Viewer button that exports the rendered report.")
									   target:self
									   action:@selector(exportReportAction:)];
	_exportButton.image = MADViewerSymbolImage(@"square.and.arrow.up", NSLocalizedString(@"Export Report", @"Accessibility description for the export button icon."));
	_exportButton.imagePosition = NSImageLeft;
	_exportButton.bezelStyle = NSBezelStyleRounded;
	_exportButton.toolTip = NSLocalizedString(@"Export the report as PDF, HTML, CSV, JSON, or text (⌘E).", @"Tooltip for the viewer export button.");
	_exportButton.accessibilityLabel = NSLocalizedString(@"Export Report", @"Accessibility label for the viewer export button.");

	_connectionButton = [NSButton buttonWithImage:MADViewerSymbolImage(@"ellipsis.circle", NSLocalizedString(@"More", @"Accessibility description for the viewer overflow button."))
										   target:self
										   action:@selector(showOverflowMenu:)];
	_connectionButton.bezelStyle = NSBezelStyleRounded;
	_connectionButton.imagePosition = NSImageOnly;
	_connectionButton.toolTip = NSLocalizedString(@"More report actions.", @"Tooltip for the viewer overflow button.");
	_connectionButton.accessibilityLabel = NSLocalizedString(@"More Report Actions", @"Accessibility label for the viewer overflow button.");
	_overflowButton = _connectionButton;

	NSView *spacer = [[NSView alloc] initWithFrame:NSZeroRect];
	[spacer setContentHuggingPriority:1 forOrientation:NSLayoutConstraintOrientationHorizontal];

	NSStackView *topStack = [NSStackView stackViewWithViews:@[
		_refreshButton, spacer, _printButton, _exportButton, _connectionButton
	]];
	topStack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	topStack.spacing = 8;
	topStack.alignment = NSLayoutAttributeCenterY;
	topStack.edgeInsets = NSEdgeInsetsMake(6, 14, 6, 14);
	topStack.frame = topBar.bounds;
	topStack.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	[topBar addSubview:topStack];

	// 2. Center: a framed fixed-size paginated report, or the row grid for a node with no layout.
	NSRect pdfFrame = NSMakeRect(0,
								 kViewerBottomStatusBarHeight,
								 1180,
								 740 - kViewerTopToolbarHeight - kViewerBottomStatusBarHeight);
	_pdfView = [[PDFView alloc] initWithFrame:pdfFrame];
	_pdfView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	_pdfView.autoScales = NO;
	_pdfView.displayMode = kPDFDisplaySinglePageContinuous;
	_pdfView.displaysPageBreaks = YES;
	_pdfView.pageBreakMargins = NSEdgeInsetsMake(24.0, 24.0, 24.0, 24.0);
	_pdfView.minScaleFactor = 0.25;
	_pdfView.maxScaleFactor = 4.0;
	_pdfView.scaleFactor = _zoomScale;
	_pdfView.backgroundColor = [NSColor underPageBackgroundColor];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(pdfViewScaleChanged:)
												 name:PDFViewScaleChangedNotification
											   object:_pdfView];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(pdfViewPageChanged:)
												 name:PDFViewPageChangedNotification
											   object:_pdfView];

	_rowGridView = [[NSTableView alloc] initWithFrame:pdfFrame];
	_rowGridView.usesAlternatingRowBackgroundColors = YES;
	_rowGridView.rowHeight = 22.0;
	_rowGridView.allowsMultipleSelection = YES;
	_rowGridView.dataSource = self;
	_rowGridView.delegate = self;

	_rowGridScrollView = [[NSScrollView alloc] initWithFrame:pdfFrame];
	_rowGridScrollView.documentView = _rowGridView;
	_rowGridScrollView.hasVerticalScroller = YES;
	_rowGridScrollView.hasHorizontalScroller = YES;
	_rowGridScrollView.autohidesScrollers = YES;
	_rowGridScrollView.borderType = NSBezelBorder;
	_rowGridScrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	_rowGridScrollView.hidden = YES;

	// 3. Bottom Status Bar: status on the left, page/zoom/paper controls on the right.
	_statusBarView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 1180, kViewerBottomStatusBarHeight)];
	_statusBarView.autoresizingMask = NSViewWidthSizable | NSViewMaxYMargin;
	_statusBarView.wantsLayer = YES;
	_statusBarView.layer.backgroundColor = [NSColor windowBackgroundColor].CGColor;

	NSBox *bottomSep = [[NSBox alloc] initWithFrame:NSMakeRect(0, kViewerBottomStatusBarHeight - 1.0, 1180, 1.0)];
	bottomSep.boxType = NSBoxSeparator;
	bottomSep.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
	[_statusBarView addSubview:bottomSep];

	_spinner = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 14, 14)];
	_spinner.style = NSProgressIndicatorStyleSpinning;
	_spinner.controlSize = NSControlSizeSmall;
	_spinner.displayedWhenStopped = NO;

	_statusLabel = [NSTextField labelWithString:NSLocalizedString(@"Not yet refreshed. Click “Refresh” to query the database and render the report.", @"Viewer status line before the first refresh. The quoted word matches the Refresh button.")];
	_statusLabel.font = [NSFont systemFontOfSize:11.5];
	_statusLabel.textColor = [NSColor secondaryLabelColor];
	_statusLabel.lineBreakMode = NSLineBreakByTruncatingTail;
	_statusLabel.accessibilityLabel = NSLocalizedString(@"Report Status", @"Accessibility label for the viewer status line.");

	_zoomOutButton = [NSButton buttonWithImage:MADViewerSymbolImage(@"minus.magnifyingglass", NSLocalizedString(@"Zoom Out", @"Accessibility description for the zoom-out icon."))
										target:self
										action:@selector(zoomOutAction:)];
	_zoomOutButton.bezelStyle = NSBezelStyleRounded;
	_zoomOutButton.controlSize = NSControlSizeSmall;
	_zoomOutButton.toolTip = NSLocalizedString(@"Zoom Out", @"Tooltip for the zoom-out button.");
	_zoomOutButton.accessibilityLabel = NSLocalizedString(@"Zoom Out", @"Accessibility label for the zoom-out button.");

	_zoomLabelButton = [NSButton buttonWithTitle:@"100%"
										  target:self
										  action:@selector(zoomActualSizeAction:)];
	_zoomLabelButton.bezelStyle = NSBezelStyleRounded;
	_zoomLabelButton.controlSize = NSControlSizeSmall;
	_zoomLabelButton.font = [NSFont monospacedDigitSystemFontOfSize:10.5 weight:NSFontWeightMedium];
	_zoomLabelButton.toolTip = NSLocalizedString(@"Reset Zoom to 100% (Actual Page Size)", @"Tooltip for the zoom percentage button.");
	_zoomLabelButton.accessibilityLabel = NSLocalizedString(@"Reset Zoom", @"Accessibility label for the zoom percentage button.");

	_zoomInButton = [NSButton buttonWithImage:MADViewerSymbolImage(@"plus.magnifyingglass", NSLocalizedString(@"Zoom In", @"Accessibility description for the zoom-in icon."))
									   target:self
									   action:@selector(zoomInAction:)];
	_zoomInButton.bezelStyle = NSBezelStyleRounded;
	_zoomInButton.controlSize = NSControlSizeSmall;
	_zoomInButton.toolTip = NSLocalizedString(@"Zoom In", @"Tooltip for the zoom-in button.");
	_zoomInButton.accessibilityLabel = NSLocalizedString(@"Zoom In", @"Accessibility label for the zoom-in button.");

	_prevPageButton = [NSButton buttonWithImage:MADViewerSymbolImage(@"chevron.left", NSLocalizedString(@"Previous Page", @"Accessibility description for the previous-page icon."))
										 target:self
										 action:@selector(previousPageAction:)];
	_prevPageButton.bezelStyle = NSBezelStyleRounded;
	_prevPageButton.controlSize = NSControlSizeSmall;
	_prevPageButton.toolTip = NSLocalizedString(@"Previous Page", @"Tooltip for the previous-page button.");
	_prevPageButton.accessibilityLabel = NSLocalizedString(@"Previous Page", @"Accessibility label for the previous-page button.");

	_pageNumberLabel = [NSTextField labelWithString:NSLocalizedString(@"Page 0 of 0", @"Viewer page-number placeholder before a report is rendered.")];
	_pageNumberLabel.font = [NSFont monospacedDigitSystemFontOfSize:10.5 weight:NSFontWeightRegular];
	_pageNumberLabel.textColor = [NSColor secondaryLabelColor];
	_pageNumberLabel.alignment = NSTextAlignmentCenter;
	_pageNumberLabel.accessibilityLabel = NSLocalizedString(@"Page Number", @"Accessibility label for the viewer page-number label.");

	_nextPageButton = [NSButton buttonWithImage:MADViewerSymbolImage(@"chevron.right", NSLocalizedString(@"Next Page", @"Accessibility description for the next-page icon."))
										 target:self
										 action:@selector(nextPageAction:)];
	_nextPageButton.bezelStyle = NSBezelStyleRounded;
	_nextPageButton.controlSize = NSControlSizeSmall;
	_nextPageButton.toolTip = NSLocalizedString(@"Next Page", @"Tooltip for the next-page button.");
	_nextPageButton.accessibilityLabel = NSLocalizedString(@"Next Page", @"Accessibility label for the next-page button.");

	_pageSizePopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	_pageSizePopup.target = self;
	_pageSizePopup.action = @selector(pageSizePopupChanged:);
	_pageSizePopup.controlSize = NSControlSizeSmall;
	_pageSizePopup.font = [NSFont systemFontOfSize:10.5];
	_pageSizePopup.toolTip = NSLocalizedString(@"Choose the paper size, then refresh to render at that size.", @"Tooltip for the viewer paper-size popup.");
	_pageSizePopup.accessibilityLabel = NSLocalizedString(@"Page Size", @"Accessibility label for the viewer paper-size popup.");
	for (NSNumber *typeNum in [MTPaper standardPaperTypes]) {
		MTPaperType type = (MTPaperType)typeNum.integerValue;
		NSString *title = [MTPaper displayNameForPaperType:type];
		[_pageSizePopup addItemWithTitle:title];
		_pageSizePopup.lastItem.representedObject = typeNum;
	}
	[self syncPageSizePopupSelection];

	_paperStatusLabel = [NSTextField labelWithString:[[NSString alloc] initWithFormat:NSLocalizedString(@"Rendered Page Size: %@", @"Viewer status line. %@ is a paper name such as A4."), [MTPaper displayNameForPaperType:_renderedPaperType]]];
	_paperStatusLabel.font = [NSFont systemFontOfSize:10.5 weight:NSFontWeightMedium];
	_paperStatusLabel.textColor = [NSColor tertiaryLabelColor];
	_paperStatusLabel.accessibilityLabel = _paperStatusLabel.stringValue;
	[_paperStatusLabel setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];

	NSView *statusSpacer = [[NSView alloc] initWithFrame:NSZeroRect];
	[statusSpacer setContentHuggingPriority:1 forOrientation:NSLayoutConstraintOrientationHorizontal];

	NSBox *zoomSep = [[NSBox alloc] init];
	zoomSep.boxType = NSBoxSeparator;
	[zoomSep.widthAnchor constraintEqualToConstant:1.0].active = YES;
	[zoomSep.heightAnchor constraintEqualToConstant:14.0].active = YES;
	NSBox *pageSep = [[NSBox alloc] init];
	pageSep.boxType = NSBoxSeparator;
	[pageSep.widthAnchor constraintEqualToConstant:1.0].active = YES;
	[pageSep.heightAnchor constraintEqualToConstant:14.0].active = YES;

	_pageControlsStack = [NSStackView stackViewWithViews:@[
		_zoomOutButton, _zoomLabelButton, _zoomInButton, zoomSep,
		_prevPageButton, _pageNumberLabel, _nextPageButton, pageSep,
		_pageSizePopup, _paperStatusLabel
	]];
	_pageControlsStack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	_pageControlsStack.spacing = 5.0;
	_pageControlsStack.alignment = NSLayoutAttributeCenterY;
	_pageControlsStack.translatesAutoresizingMaskIntoConstraints = NO;

	NSStackView *statusStack = [NSStackView stackViewWithViews:@[
		_spinner, _statusLabel, statusSpacer, _pageControlsStack
	]];
	statusStack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	statusStack.spacing = 8;
	statusStack.alignment = NSLayoutAttributeCenterY;
	statusStack.edgeInsets = NSEdgeInsetsMake(2, 12, 2, 12);
	statusStack.frame = _statusBarView.bounds;
	statusStack.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	[_statusBarView addSubview:statusStack];

	[root addSubview:topBar];
	[root addSubview:_pdfView];
	[root addSubview:_rowGridScrollView];
	[root addSubview:_statusBarView];

	_tipBar = [MADMacTipBar tipBarWithIdentifier:@"viewer"
											text:NSLocalizedString(@"Start here: press Refresh to run the query. Use the bottom bar to zoom, page through, or change the paper size.", @"First-run tip in the viewer workspace.")];
	_tipBar.frame = NSMakeRect(0.0, 740.0 - kViewerTopToolbarHeight - 30.0, 1180.0, 30.0);
	_tipBar.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
	[root addSubview:_tipBar];

	self.view = root;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleDocumentReplaced:)
												 name:@"MADMacDocumentDidReplaceHeadlessNotification"
											   object:_document];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleDocumentRefreshed:)
												 name:MADMacDocumentDidRefreshNotification
											   object:_document];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleDocumentSelectionChanged:)
												 name:MADMacDocumentDidSelectQueryNotification
											   object:_document];
	[self reloadPreview];
}

- (void)handleDocumentReplaced:(NSNotification *) __unused note {
	if (_document.headlessDocument != nil) {
		[_document.headlessDocument setPaperType:_renderedPaperType];
	}
	[self reloadPreview];
}

- (void)handleDocumentRefreshed:(NSNotification *) __unused note {
	[self reloadPreview];
}

- (void)handleDocumentSelectionChanged:(NSNotification *) __unused note {
	// reloadPreview clears the previous node's PDF/grid first, so it never flashes.
	[self reloadPreview];
}

#pragma mark - Page Size Selection & Persistence

- (void)syncPageSizePopupSelection {
	if (_pageSizePopup == nil) return;
	for (NSMenuItem *item in _pageSizePopup.itemArray) {
		NSNumber *num = item.representedObject;
		if (num != nil && (MTPaperType)num.integerValue == _selectedPaperType) {
			[_pageSizePopup selectItem:item];
			return;
		}
	}
}

- (void)selectPaperType:(MTPaperType)paperType {
	_selectedPaperType = paperType;
	[self syncPageSizePopupSelection];
}

- (void)pageSizePopupChanged:(NSPopUpButton *)sender {
	NSNumber *typeNum = sender.selectedItem.representedObject;
	if (typeNum != nil) {
		_selectedPaperType = (MTPaperType)typeNum.integerValue;
	}
}

#pragma mark - Zoom & Page Navigation

- (void)setZoomScale:(CGFloat)zoomScale {
	CGFloat clamped = MAX(0.25, MIN(4.0, zoomScale));
	_zoomScale = clamped;
	if (_pdfView != nil) {
		_pdfView.autoScales = NO;
		_pdfView.scaleFactor = clamped;
	}
	[self updateZoomAndPageControls];
}

- (void)zoomInAction:(id) __unused sender {
	[self setZoomScale:(_zoomScale * 1.25)];
}

- (void)zoomOutAction:(id) __unused sender {
	[self setZoomScale:(_zoomScale / 1.25)];
}

- (void)zoomActualSizeAction:(id) __unused sender {
	[self setZoomScale:1.0];
}

- (void)previousPageAction:(id) __unused sender {
	if (_pdfView.canGoToPreviousPage) {
		[_pdfView goToPreviousPage:nil];
		[self updateZoomAndPageControls];
	}
}

- (void)nextPageAction:(id) __unused sender {
	if (_pdfView.canGoToNextPage) {
		[_pdfView goToNextPage:nil];
		[self updateZoomAndPageControls];
	}
}

- (void)pdfViewScaleChanged:(NSNotification *) __unused note {
	if (_pdfView != nil && !_pdfView.autoScales && _pdfView.scaleFactor > 0.0) {
		_zoomScale = _pdfView.scaleFactor;
		[self updateZoomAndPageControls];
	}
}

- (void)pdfViewPageChanged:(NSNotification *) __unused note {
	[self updateZoomAndPageControls];
}

- (void)updateZoomAndPageControls {
	NSInteger pct = (NSInteger)llround(_zoomScale * 100.0);
	_zoomLabelButton.title = [NSString stringWithFormat:@"%ld%%", (long)pct];
	BOOL grid = [self isShowingRowGrid];
	_zoomOutButton.enabled = !grid;
	_zoomLabelButton.enabled = !grid;
	_zoomInButton.enabled = !grid;

	PDFDocument *pdfDoc = _pdfView.document;
	NSUInteger totalPages = pdfDoc != nil ? pdfDoc.pageCount : 0;
	if (totalPages == 0) {
		_pageNumberLabel.stringValue = NSLocalizedString(@"Page 0 of 0", @"Viewer page-number placeholder before a report is rendered.");
		_prevPageButton.enabled = NO;
		_nextPageButton.enabled = NO;
	} else {
		PDFPage *curPage = _pdfView.currentPage;
		NSUInteger curIdx = curPage != nil ? [pdfDoc indexForPage:curPage] + 1 : 1;
		_pageNumberLabel.stringValue = [[NSString alloc] initWithFormat:NSLocalizedString(@"Page %1$lu of %2$lu", @"Viewer page-number label. %1$lu is the current page, %2$lu the total."),
										(unsigned long)curIdx,
										(unsigned long)totalPages];
		_prevPageButton.enabled = _pdfView.canGoToPreviousPage;
		_nextPageButton.enabled = _pdfView.canGoToNextPage;
	}
	_paperStatusLabel.stringValue = [[NSString alloc] initWithFormat:NSLocalizedString(@"Rendered Page Size: %@", @"Viewer status line. %@ is a paper name such as A4."),
									 [MTPaper displayNameForPaperType:_renderedPaperType]];
}

#pragma mark - Refresh & Render

- (NSString *)formattedMessageForError:(nullable NSError *)error fallback:(NSString *)fallback {
	if (error == nil) {
		return fallback;
	}
	NSString *desc = error.localizedDescription ?: fallback;
	NSString *reason = error.localizedFailureReason;
	if (reason.length > 0 && ![reason isEqualToString:desc] && ![desc containsString:reason]) {
		return [NSString stringWithFormat:@"%@ — %@", desc, reason];
	}
	return desc;
}

- (BOOL)isAuthenticationError:(nullable NSError *)error {
	if (error == nil) {
		return NO;
	}
	if ([error.domain isEqualToString:@"com.everydayapps.operation.refresh"] && error.code == 3) {
		return YES;
	}
	NSString *combined = [[NSString stringWithFormat:@"%@ %@",
						   error.localizedDescription ?: @"",
						   error.localizedFailureReason ?: @""] lowercaseString];
	return ([combined containsString:@"access denied"] ||
			[combined containsString:@"authentication"] ||
			[combined containsString:@"password"] ||
			[combined containsString:@"login failed"] ||
			[combined containsString:@"credentials"] ||
			[combined containsString:@"fe_sendauth"]);
}

- (void)showOverflowMenu:(NSView *)sender {
	NSMenu *menu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"More Report Actions", @"Title of the viewer's overflow menu. Never shown to the user.")];
	menu.autoenablesItems = NO;

	NSMenuItem *connection = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Database Connection…", @"Viewer menu item that edits the database connection.")
													   action:@selector(editDatabaseConnectionAction:)
												keyEquivalent:@""];
	connection.target = self;
	connection.toolTip = NSLocalizedString(@"Edit the database connection settings.", @"Tooltip for the viewer connection menu item.");
	if (@available(macOS 11.0, *)) {
		connection.image = MADViewerSymbolImage(@"cylinder.split.1x2", nil);
	}
	[menu addItem:connection];
	[menu addItem:[NSMenuItem separatorItem]];

	BOOL grid = [self isShowingRowGrid];
	NSArray<NSArray *> *rows = @[
		@[NSLocalizedString(@"Zoom In", @"Viewer menu item that zooms in."), NSStringFromSelector(@selector(zoomInAction:))],
		@[NSLocalizedString(@"Zoom Out", @"Viewer menu item that zooms out."), NSStringFromSelector(@selector(zoomOutAction:))],
		@[NSLocalizedString(@"Actual Size", @"Viewer menu item that resets zoom to 100%."), NSStringFromSelector(@selector(zoomActualSizeAction:))],
	];
	for (NSArray *row in rows) {
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:row[0] action:NSSelectorFromString(row[1]) keyEquivalent:@""];
		item.target = self;
		item.enabled = !grid;
		[menu addItem:item];
	}
	[menu popUpMenuPositioningItem:nil atLocation:NSMakePoint(0.0, NSHeight(sender.bounds) + 2.0) inView:sender];
}

- (void)editDatabaseConnectionAction:(nullable id) __unused sender {
	NSWindowController *wc = self.view.window.windowController;
	if ([wc isKindOfClass:[MADMacWindowController class]]) {
		__weak typeof(self) weakSelf = self;
		[(MADMacWindowController *)wc presentConnectionSettingsWithPrompt:nil onUpdated:^{
			[weakSelf performRefreshWithSuccessHandler:nil];
		}];
	}
}

- (void)locateMissingSQLiteDatabaseWithURL:(NSURL *)url
								completion:(nullable void (^)(BOOL success, NSError * _Nullable error))completion {
	if (url == nil || _document == nil) {
		if (completion) {
			completion(NO, [NSError errorWithDomain:@"MADMacViewer" code:1 userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"No SQLite file URL selected.", @"Error: the user must choose a SQLite database file.") }]);
		}
		return;
	}
	MADDatabaseConnectionSqlite3 *newConn = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:url];
	[_document updateDatabaseConnection:newConn credentials:nil saveToKeychain:NO];

	__weak typeof(self) weakSelf = self;
	[_document refreshDataWithPassword:nil completion:^(BOOL success, NSError * _Nullable error) {
		__strong typeof(weakSelf) strongSelf = weakSelf;
		if (strongSelf != nil) {
			if (success) {
				strongSelf.lastRefreshError = nil;
				[strongSelf reloadPreview];
			} else {
				strongSelf.lastRefreshError = error;
				strongSelf.statusLabel.stringValue = [strongSelf formattedMessageForError:error fallback:NSLocalizedString(@"Refresh failed.", @"Viewer status line: the refresh failed with no more specific reason.")];
				strongSelf.statusLabel.textColor = [NSColor systemRedColor];
			}
		}
		if (completion) {
			completion(success, error);
		}
	}];
}

- (void)handleRefreshFailureWithError:(nullable NSError *)error
					   onRetrySuccess:(nullable void (^)(void))onRetrySuccess {
	_lastRefreshError = error;
	_statusLabel.stringValue = [self formattedMessageForError:error fallback:NSLocalizedString(@"Refresh failed.", @"Viewer status line: the refresh failed with no more specific reason.")];
	_statusLabel.textColor = [NSColor systemRedColor];

	MADHeadlessDocument *doc = _document.headlessDocument;
	MADDatabaseConnection *conn = doc.database.databaseConnection;
	BOOL isSQLite = (conn.databaseType == MADDatabaseTypeSqlite3);

	NSWindow *win = self.view.window;
	MADMacWindowController *wc = [win.windowController isKindOfClass:[MADMacWindowController class]]
		? (MADMacWindowController *)win.windowController
		: nil;

	// Case 1: SQLite File Not Found
	if (isSQLite && ([error.domain isEqualToString:MADDatabaseSqlite3ErrorDomain] &&
					 (error.code == MADDatabaseSqlite3ErrorFileNotFound || error.code == MADDatabaseSqlite3ErrorConnectFailed))) {
		if (win == nil || !win.isVisible) {
			return;
		}
		NSString *expectedPath = error.userInfo[NSFilePathErrorKey];
		if (expectedPath.length == 0 && [conn conformsToProtocol:@protocol(MADDatabaseConnectionsPropertiesURL)]) {
			expectedPath = ((id <MADDatabaseConnectionsPropertiesURL>)conn).databaseUrl.path;
		}
		if (expectedPath.length == 0) {
			expectedPath = _document.rptqDatabase.ownedByUser.host ?: _document.rptqDatabase.ownedByUser.dbname ?: @"database.sqlite3";
		}
		NSString *fileName = expectedPath.lastPathComponent.length > 0 ? expectedPath.lastPathComponent : @"SQLite database";

		NSAlert *alert = [[NSAlert alloc] init];
		alert.alertStyle = NSAlertStyleWarning;
		alert.messageText = [[NSString alloc] initWithFormat:NSLocalizedString(@"Database File “%@” Could Not Be Found", @"Refresh alert title. %@ is the missing SQLite file name."), fileName];
		alert.informativeText = [[NSString alloc] initWithFormat:NSLocalizedString(@"MAD Designer could not find the SQLite database file for this report at:\n%@\n\nWould you like to locate the database file on your Mac?", @"Refresh alert body. %@ is the expected file path. The last sentence asks whether to open a file chooser."), expectedPath];
		[alert addButtonWithTitle:NSLocalizedString(@"Locate File…", @"Refresh alert button that opens a file chooser for the missing database.")];
		[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Refresh alert button that dismisses the alert.")];

		__weak typeof(self) weakSelf = self;
		[alert beginSheetModalForWindow:win completionHandler:^(NSModalResponse returnCode) {
			__strong typeof(weakSelf) strongSelf = weakSelf;
			if (strongSelf == nil || returnCode != NSAlertFirstButtonReturn) {
				return;
			}
			NSOpenPanel *panel = [NSOpenPanel openPanel];
			panel.title = [[NSString alloc] initWithFormat:NSLocalizedString(@"Locate “%@”", @"Open panel title when locating a missing database. %@ is the file name."), fileName];
			panel.message = [[NSString alloc] initWithFormat:NSLocalizedString(@"Select the SQLite database file “%@” for this report.", @"Open panel message when locating a missing database. %@ is the file name."), fileName];
			panel.canChooseFiles = YES;
			panel.canChooseDirectories = NO;
			panel.allowsMultipleSelection = NO;
			if (strongSelf.document.fileURL.isFileURL) {
				panel.directoryURL = [strongSelf.document.fileURL URLByDeletingLastPathComponent];
			}
			[panel beginSheetModalForWindow:win completionHandler:^(NSModalResponse panelResp) {
				if (panelResp == NSModalResponseOK && panel.URL != nil) {
					[strongSelf locateMissingSQLiteDatabaseWithURL:panel.URL completion:^(BOOL ok, NSError * _Nullable retryErr) {
						if (ok && onRetrySuccess) {
							onRetrySuccess();
						} else if (!ok && retryErr != nil) {
							[strongSelf handleRefreshFailureWithError:retryErr onRetrySuccess:onRetrySuccess];
						}
					}];
				}
			}];
		}];
		return;
	}

	// Case 2: Server Database Needs Credentials or Authentication Failed
	if (!isSQLite && [self isAuthenticationError:error]) {
		if (wc != nil && win != nil && win.isVisible) {
			NSString *prompt = [self formattedMessageForError:error fallback:NSLocalizedString(@"Enter credentials to connect to the database server.", @"Prompt shown when the database server rejected the credentials.")];
			__weak typeof(self) weakSelf = self;
			[wc presentConnectionSettingsWithPrompt:prompt onUpdated:^{
				[weakSelf performRefreshWithSuccessHandler:onRetrySuccess];
			}];
		}
		return;
	}

	// Case 3: Server Database Unreachable / Network Error / SQL Error
	if (win != nil && win.isVisible) {
		NSAlert *alert = [[NSAlert alloc] init];
		alert.alertStyle = NSAlertStyleWarning;
		alert.messageText = error.localizedDescription ?: NSLocalizedString(@"Could Not Refresh Report Data", @"Refresh alert title when there is no more specific error message.");
		NSString *reason = error.localizedFailureReason;
		alert.informativeText = (reason.length > 0 && ![reason isEqualToString:alert.messageText])
			? reason
			: NSLocalizedString(@"Check that the database server is reachable and your connection settings are valid.", @"Refresh alert body suggesting the likely causes.");
		[alert addButtonWithTitle:NSLocalizedString(@"Connection Settings…", @"Refresh alert button that opens the database connection settings.")];
		[alert addButtonWithTitle:NSLocalizedString(@"Retry", @"Refresh alert button that tries the refresh again.")];
		[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Refresh alert button that dismisses the alert.")];

		__weak typeof(self) weakSelf = self;
		[alert beginSheetModalForWindow:win completionHandler:^(NSModalResponse returnCode) {
			__strong typeof(weakSelf) strongSelf = weakSelf;
			if (strongSelf == nil) return;
			if (returnCode == NSAlertFirstButtonReturn && wc != nil) {
				NSString *prompt = [strongSelf formattedMessageForError:error fallback:nil];
				[wc presentConnectionSettingsWithPrompt:prompt onUpdated:^{
					[strongSelf performRefreshWithSuccessHandler:onRetrySuccess];
				}];
			} else if (returnCode == NSAlertSecondButtonReturn) {
				[strongSelf performRefreshWithSuccessHandler:onRetrySuccess];
			}
		}];
	}
}

- (void)performRefreshWithSuccessHandler:(nullable void (^)(void))onSuccess {
	MADHeadlessDocument *doc = _document.headlessDocument;
	if (doc == nil) return;

	_renderedPaperType = _selectedPaperType ?: MTPaperTypeLetter;
	[doc setPaperType:_renderedPaperType];
	_renderedPaperSize = doc.paperSize;

	[_spinner startAnimation:nil];
	_statusLabel.stringValue = NSLocalizedString(@"Executing SQL query and formatting report pages…", @"Viewer status line while refresh and rendering are running.");
	_statusLabel.textColor = [NSColor secondaryLabelColor];

	__weak typeof(self) weakSelf = self;
	[_document refreshDataWithPassword:nil completion:^(BOOL success, NSError * _Nullable error) {
		__strong typeof(weakSelf) strongSelf = weakSelf;
		if (!strongSelf) return;
		[strongSelf.spinner stopAnimation:nil];
		if (!success) {
			[strongSelf handleRefreshFailureWithError:error onRetrySuccess:onSuccess];
			return;
		}
		strongSelf.lastRefreshError = nil;
		[strongSelf reloadPreview];
		if (onSuccess) {
			onSuccess();
		}
	}];
}

- (void)refreshReportAction:(id) __unused sender {
	[self performRefreshWithSuccessHandler:nil];
}

- (BOOL)isShowingRowGrid {
	return _rowGridScrollView != nil && !_rowGridScrollView.hidden;
}

- (NSString *)selectedNodeName {
	RptqQuery *query = _document.selectedQuery;
	return query.name.length > 0
		? query.name
		: NSLocalizedString(@"Query", @"Default query name in the selector.");
}

/// YES when the selected node's own ordered bands carry at least one element.
- (BOOL)selectedNodeHasElements {
	for (RptqDocumentSection *section in [_document orderedSections]) {
		for (RptqDocumentSectionRows *row in section.hasRows) {
			if (row.hasObjects.count > 0) return YES;
		}
	}
	return NO;
}

/// Clears the PDF and the row grid so a previous node's content never flashes.
- (void)clearPreviewContent {
	if (_pdfView != nil) _pdfView.document = nil;
	if (_rowGridScrollView != nil) _rowGridScrollView.hidden = YES;
	// Until something renders, paging, zoom, and paper controls have nothing to act on.
	if (_pageControlsStack != nil) _pageControlsStack.hidden = YES;
	_gridRows = @[];
	[_rowGridView reloadData];
	if (_printButton != nil) _printButton.enabled = YES;
}

- (void)showRowGridForResult:(MADDataResult *)result {
	MADDataTableFast *table = result.dataTable;
	NSArray<NSString *> *keys = result.columnKeys ?: @[];
	NSMutableArray<NSDictionary<NSString *, id> *> *rows =
		[[NSMutableArray alloc] initWithCapacity:result.numberOfRows];
	for (NSUInteger i = 0; i < result.numberOfRows; i++) {
		NSError *error = nil;
		NSDictionary *row = [table dataForRow:i + 1 error:&error];
		[rows addObject:row ?: @{}];
	}

	while (_rowGridView.numberOfColumns > 0) {
		[_rowGridView removeTableColumn:_rowGridView.tableColumns.lastObject];
	}
	NSUInteger index = 0;
	for (NSString *key in keys) {
		// The logical field key is the readable column name (an output key for a composed
		// node, "<alias>.<field>" for a leaf); the column's SQL expression is not.
		NSString *title = key;
		if (title.length == 0) {
			title = [NSString localizedStringWithFormat:
				NSLocalizedString(@"Column %lu", @"Fallback row-grid column header when the result carries no column name. %lu is the column number."),
				(unsigned long)(index + 1)];
		}
		NSTableColumn *tableColumn = [[NSTableColumn alloc] initWithIdentifier:key];
		tableColumn.title = title;
		tableColumn.width = 120.0;
		tableColumn.minWidth = 60.0;
		[_rowGridView addTableColumn:tableColumn];
		index++;
	}
	_gridRows = rows;
	[_rowGridView reloadData];

	_rowGridScrollView.hidden = NO;
	_pdfView.hidden = YES;
	_printButton.enabled = NO;
	// Rows have no pages, zoom, or paper: hide those controls rather than leaving them dead.
	_pageControlsStack.hidden = YES;
}

- (void)reloadPreview {
	MADHeadlessDocument *doc = _document.headlessDocument;
	[self clearPreviewContent];
	if (doc == nil) {
		_statusLabel.stringValue = NSLocalizedString(@"Not yet refreshed. Click “Refresh” to query the database and render the report.", @"Viewer status line before the first refresh. The quoted word matches the Refresh button.");
		_statusLabel.textColor = [NSColor secondaryLabelColor];
		[self updateZoomAndPageControls];
		return;
	}

	BOOL isReportRoot = [_document queryIsReportRoot:_document.selectedQuery];
	if (!doc.refreshed) {
		_statusLabel.stringValue = isReportRoot
			? NSLocalizedString(@"Not yet refreshed. Click “Refresh” to query the database and render the report.", @"Viewer status line before the first refresh. The quoted word matches the Refresh button.")
			: [NSString localizedStringWithFormat:
				NSLocalizedString(@"“%@” has no data yet. Click “Refresh” to load the composition.", @"Viewer status line before the first refresh while a source is selected. %@ is the source's name."),
				[self selectedNodeName]];
		_statusLabel.textColor = [NSColor secondaryLabelColor];
		[self updateZoomAndPageControls];
		return;
	}

	[doc setPaperType:_renderedPaperType];
	_renderedPaperSize = doc.paperSize;

	MADDataResult *result = [_document resultForQuery:_document.selectedQuery];
	if (result == nil) {
		_statusLabel.stringValue = [NSString localizedStringWithFormat:
			NSLocalizedString(@"“%@” has no data yet. Click “Refresh” to load the composition.", @"Viewer status line before the first refresh while a source is selected. %@ is the source's name."),
			[self selectedNodeName]];
		_statusLabel.textColor = [NSColor secondaryLabelColor];
		[self updateZoomAndPageControls];
		return;
	}

	NSUInteger rowCount = result.numberOfRows;

	if (![self selectedNodeHasElements]) {
		// A node with no layout is a report of rows, not an error.
		[self showRowGridForResult:result];
		_statusLabel.stringValue = [NSString localizedStringWithFormat:
			NSLocalizedString(@"No report layout; showing %lu cached rows.", @"Viewer status line when a node with no elements is shown as a row grid. %lu is the row count."),
			(unsigned long)rowCount];
		_statusLabel.textColor = [NSColor systemGreenColor];
		[self updateZoomAndPageControls];
		return;
	}

	// Render the selected node's PDF into a temporary file using the locked paper type.
	NSString *tmpPDF = [NSTemporaryDirectory() stringByAppendingPathComponent:
						[NSString stringWithFormat:@"mad-preview-%@.pdf", NSUUID.UUID.UUIDString]];
	NSURL *tmpPDFURL = [NSURL fileURLWithPath:tmpPDF];
	NSError *pdfErr = nil;
	BOOL exported = [self exportCurrentNodeInFormat:@"pdf" toURL:tmpPDFURL error:&pdfErr];
	if (exported) {
		PDFDocument *pdfDoc = [[PDFDocument alloc] initWithURL:tmpPDFURL];
		_pdfView.autoScales = NO;
		_pdfView.document = pdfDoc;
		_pdfView.scaleFactor = _zoomScale;
		_pdfView.hidden = NO;
		_rowGridScrollView.hidden = YES;
		_pageControlsStack.hidden = NO;
		_printButton.enabled = (pdfDoc != nil);
	}
	[[NSFileManager defaultManager] removeItemAtURL:tmpPDFURL error:NULL];

	if (!exported) {
		_statusLabel.stringValue = [self formattedMessageForError:pdfErr
														fallback:NSLocalizedString(@"Could not render the report.", @"Viewer status line when the PDF preview failed.")];
		_statusLabel.textColor = [NSColor systemRedColor];
		[self updateZoomAndPageControls];
		return;
	}

	NSUInteger pageCount = _pdfView.document ? _pdfView.document.pageCount : 0;
	_statusLabel.stringValue = [MADMacViewerViewController statusMessageForPageCount:pageCount
																			rowCount:rowCount];
	_statusLabel.textColor = [NSColor systemGreenColor];
	[self updateZoomAndPageControls];
}

/// Exports the selected node.  The no-query form is the report root's only; a non-root
/// node never falls back to it (that would silently write the root's rows).
- (BOOL)exportCurrentNodeInFormat:(NSString *)formatName
							toURL:(NSURL *)url
							error:(NSError * _Nullable __autoreleasing *)error {
	MADHeadlessDocument *doc = _document.headlessDocument;
	if (doc == nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"MADMacViewer" code:1 userInfo:@{
				NSLocalizedDescriptionKey: NSLocalizedString(@"No active document to export.", @"Error: an export was requested with no open report.") }];
		}
		return NO;
	}
	Class<MADReportExporting> cls = [MADReportExporterRegistry exporterClassForFormat:formatName];
	if (cls == Nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"MADMacViewer" code:2 userInfo:@{
				NSLocalizedDescriptionKey: [[NSString alloc] initWithFormat:
					NSLocalizedString(@"Unknown export format '%@'.", @"Error: the export format identifier is not registered. %@ is the identifier."), formatName] }];
		}
		return NO;
	}
	RptqQuery *query = _document.selectedQuery;
	BOOL isReportRoot = [_document queryIsReportRoot:query];
	Class exporterClass = (Class)cls;
	id<MADReportExporting> exporter = [[exporterClass alloc] init];
	if ([exporter respondsToSelector:@selector(exportDocument:query:toURL:options:error:)]) {
		return [exporter exportDocument:doc
								  query:query
								  toURL:url
								options:MADReportExportOptionsNone
								  error:error];
	}
	if (isReportRoot) {
		return [exporter exportDocument:doc toURL:url options:MADReportExportOptionsNone error:error];
	}
	if (error != NULL) {
		*error = [NSError errorWithDomain:@"MADMacViewer" code:3 userInfo:@{
			NSLocalizedDescriptionKey: NSLocalizedString(@"This format cannot export a specific node.", @"Error when a node-scoped export format does not support selecting the node.") }];
	}
	return NO;
}

#pragma mark - Row Grid Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	if (tableView == _rowGridView) return (NSInteger)_gridRows.count;
	return 0;
}

- (nullable NSString *)gridValueAtRow:(NSInteger)row columnIndex:(NSInteger)columnIndex {
	if (row < 0 || (NSUInteger)row >= _gridRows.count) return nil;
	if (columnIndex < 0 || (NSUInteger)columnIndex >= _rowGridView.numberOfColumns) return nil;
	NSString *key = _rowGridView.tableColumns[(NSUInteger)columnIndex].identifier;
	id value = _gridRows[(NSUInteger)row][key];
	if (value == nil || value == [NSNull null]) return @"";
	return [value isKindOfClass:[NSString class]] ? value : [value description];
}

- (nullable NSView *)tableView:(NSTableView *)tableView
			viewForTableColumn:(nullable NSTableColumn *)tableColumn
						   row:(NSInteger)row {
	if (tableView != _rowGridView || tableColumn == nil) return nil;
	NSInteger columnIndex = (NSInteger)[_rowGridView.tableColumns indexOfObject:tableColumn];
	NSTextField *cell = [tableView makeViewWithIdentifier:@"MADRowGridCell" owner:self];
	if (cell == nil) {
		cell = [NSTextField labelWithString:@""];
		cell.identifier = @"MADRowGridCell";
		cell.font = [NSFont systemFontOfSize:11.0];
		cell.lineBreakMode = NSLineBreakByTruncatingTail;
	}
	cell.stringValue = [self gridValueAtRow:row columnIndex:columnIndex] ?: @"";
	return cell;
}

#pragma mark - Export Dialog with Format Selection

- (NSSavePanel *)configureExportSavePanel:(NSSavePanel *)panel {
	if (panel == nil) {
		panel = [NSSavePanel savePanel];
	}
	_activeExportSavePanel = panel;

	NSView *accessory = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 360, 44)];
	NSTextField *formatLabel = [NSTextField labelWithString:NSLocalizedString(@"Export Format:", @"Export save panel label for the format popup.")];
	formatLabel.font = [NSFont systemFontOfSize:13 weight:NSFontWeightMedium];
	formatLabel.frame = NSMakeRect(16, 12, 100, 20);

	_exportFormatPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(120, 8, 224, 28) pullsDown:NO];
	_exportFormatPopup.target = self;
	_exportFormatPopup.action = @selector(exportSavePanelFormatChanged:);

	NSArray<NSString *> *preferredOrder = @[@"pdf", @"html", @"html-flow", @"csv", @"json", @"json-report", @"text"];
	BOOL isReportRoot = [_document queryIsReportRoot:_document.selectedQuery];
	for (NSString *fmt in preferredOrder) {
		// json-report is root-only in the engine; do not offer it for a source.
		if ([fmt isEqualToString:@"json-report"] && !isReportRoot) continue;
		Class<MADReportExporting> cls = [MADReportExporterRegistry exporterClassForFormat:fmt];
		if (cls != Nil && [cls isAvailable]) {
			NSString *ext = [cls fileExtension] ?: fmt;
			NSString *title = [MADMacViewerViewController friendlyTitleForExporterFormat:fmt extension:ext];
			[_exportFormatPopup addItemWithTitle:title];
			_exportFormatPopup.lastItem.representedObject = fmt;
		}
	}
	[_exportFormatPopup selectItemAtIndex:0];

	[accessory addSubview:formatLabel];
	[accessory addSubview:_exportFormatPopup];
	panel.accessoryView = accessory;

	NSString *baseName = _document.displayName.stringByDeletingPathExtension ?: @"Report";
	panel.nameFieldStringValue = [NSString stringWithFormat:@"%@.pdf", baseName];
	[self applySelectedExportFormatToSavePanel:panel];
	return panel;
}

- (void)exportSavePanelFormatChanged:(NSPopUpButton *) __unused sender {
	if (_activeExportSavePanel != nil) {
		[self applySelectedExportFormatToSavePanel:_activeExportSavePanel];
	}
}

- (void)applySelectedExportFormatToSavePanel:(NSSavePanel *)panel {
	NSString *formatName = _exportFormatPopup.selectedItem.representedObject ?: @"pdf";
	Class<MADReportExporting> cls = [MADReportExporterRegistry exporterClassForFormat:formatName];
	if (cls == Nil) return;

	NSString *ext = [cls fileExtension] ?: @"txt";
	UTType *contentType = [UTType typeWithFilenameExtension:ext];
	if (contentType != nil) {
		panel.allowedContentTypes = @[contentType];
	}
	NSString *currentName = panel.nameFieldStringValue;
	NSString *stem = currentName.stringByDeletingPathExtension;
	if (stem.length == 0) {
		stem = _document.displayName.stringByDeletingPathExtension ?: @"Report";
	}
	panel.nameFieldStringValue = [NSString stringWithFormat:@"%@.%@", stem, ext];
}

- (void)exportReportAction:(id) __unused sender {
	MADHeadlessDocument *doc = _document.headlessDocument;
	if (doc == nil) return;

	if (!doc.refreshed) {
		__weak typeof(self) weakSelf = self;
		[self performRefreshWithSuccessHandler:^{
			[weakSelf presentExportPanel];
		}];
		return;
	}
	[self presentExportPanel];
}

- (void)presentExportPanel {
	NSSavePanel *panel = [self configureExportSavePanel:[NSSavePanel savePanel]];
	NSWindow *win = self.view.window;
	__weak typeof(self) weakSelf = self;
	void (^handler)(NSModalResponse) = ^(NSModalResponse response) {
		__strong typeof(weakSelf) strongSelf = weakSelf;
		if (!strongSelf) return;
		strongSelf.activeExportSavePanel = nil;
		if (response != NSModalResponseOK || panel.URL == nil) return;

		NSString *formatName = strongSelf.exportFormatPopup.selectedItem.representedObject ?: @"pdf";
		Class<MADReportExporting> cls = [MADReportExporterRegistry exporterClassForFormat:formatName];
		if (cls == Nil) return;

		[strongSelf.document.headlessDocument setPaperType:strongSelf.renderedPaperType];
		NSError *err = nil;
		if (![strongSelf exportCurrentNodeInFormat:formatName toURL:panel.URL error:&err]) {
			if (err) [NSApp presentError:err];
		} else {
			strongSelf.statusLabel.stringValue = [[NSString alloc] initWithFormat:NSLocalizedString(@"Exported %1$@ to %2$@", @"Viewer status line after a successful export. %1$@ is the format, %2$@ the file name."),
												  formatName.uppercaseString,
												  panel.URL.lastPathComponent];
			strongSelf.statusLabel.textColor = [NSColor systemGreenColor];
		}
	};

	if (win != nil) {
		[panel beginSheetModalForWindow:win completionHandler:handler];
	} else {
		handler([panel runModal]);
	}
}

#pragma mark - Print

- (void)printReportAction:(id) __unused sender {
	if ([self isShowingRowGrid]) return; // no report layout to print
	if (_pdfView.document == nil) {
		[self refreshReportAction:nil];
		return;
	}
	NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
	[_pdfView printWithInfo:printInfo autoRotate:YES];
}

@end
