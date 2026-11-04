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

#import <MAD/MAD.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseConnectionsPropertiesURLProtocol.h>
#import <MADSqlite3/MADDataTableFast.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <Quartz/Quartz.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

static const CGFloat kViewerTopToolbarHeight = 40.0;
static const CGFloat kViewerBottomStatusBarHeight = 28.0;

@interface MADMacViewerViewController ()

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

@property (nonatomic, strong) NSProgressIndicator *spinner;
@property (nonatomic, strong) NSTextField *paperStatusLabel;
@property (nonatomic, strong) NSButton *zoomOutButton;
@property (nonatomic, strong) NSButton *zoomLabelButton;
@property (nonatomic, strong) NSButton *zoomInButton;
@property (nonatomic, strong) NSButton *prevPageButton;
@property (nonatomic, strong) NSTextField *pageNumberLabel;
@property (nonatomic, strong) NSButton *nextPageButton;

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

	// 1. Top Toolbar
	NSView *topBar = [[NSView alloc] initWithFrame:NSMakeRect(0, 740 - kViewerTopToolbarHeight, 1180, kViewerTopToolbarHeight)];
	topBar.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
	topBar.wantsLayer = YES;
	topBar.layer.backgroundColor = [NSColor windowBackgroundColor].CGColor;

	NSBox *topSep = [[NSBox alloc] initWithFrame:NSMakeRect(0, 0, 1180, 1)];
	topSep.boxType = NSBoxSeparator;
	topSep.autoresizingMask = NSViewWidthSizable | NSViewMaxYMargin;
	[topBar addSubview:topSep];

	NSTextField *pageSizeLabel = [NSTextField labelWithString:NSLocalizedString(@"Page Size:", @"Viewer toolbar label for the paper-size popup.")];
	pageSizeLabel.font = [NSFont systemFontOfSize:12 weight:NSFontWeightMedium];
	pageSizeLabel.textColor = [NSColor secondaryLabelColor];

	_pageSizePopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 210, 26) pullsDown:NO];
	_pageSizePopup.target = self;
	_pageSizePopup.action = @selector(pageSizePopupChanged:);
	for (NSNumber *typeNum in [MTPaper standardPaperTypes]) {
		MTPaperType type = (MTPaperType)typeNum.integerValue;
		NSString *title = [MTPaper displayNameForPaperType:type];
		[_pageSizePopup addItemWithTitle:title];
		_pageSizePopup.lastItem.representedObject = typeNum;
	}
	[self syncPageSizePopupSelection];

	_refreshButton = [NSButton buttonWithTitle:NSLocalizedString(@"Refresh", @"Viewer button that re-runs the query and re-renders the report.")
										target:self
										action:@selector(refreshReportAction:)];
	_refreshButton.image = [NSImage imageWithSystemSymbolName:@"arrow.clockwise"
									 accessibilityDescription:NSLocalizedString(@"Refresh Report", @"Accessibility description for the refresh button icon.")];
	_refreshButton.imagePosition = NSImageLeft;
	_refreshButton.bezelStyle = NSBezelStyleRounded;

	_connectionButton = [NSButton buttonWithTitle:NSLocalizedString(@"Connection…", @"Viewer button that opens the database connection settings.")
										   target:self
										   action:@selector(editDatabaseConnectionAction:)];
	_connectionButton.image = [NSImage imageWithSystemSymbolName:@"cylinder.split.1x2"
										accessibilityDescription:NSLocalizedString(@"Database Connection", @"Accessibility description for the connection button icon.")];
	_connectionButton.imagePosition = NSImageLeft;
	_connectionButton.bezelStyle = NSBezelStyleRounded;
	_connectionButton.toolTip = NSLocalizedString(@"Configure Database Connection Settings…", @"Tooltip for the connection button.");

	// Zoom controls
	_zoomOutButton = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"minus.magnifyingglass"
														 accessibilityDescription:NSLocalizedString(@"Zoom Out", @"Accessibility description for the zoom-out icon.")]
										target:self
										action:@selector(zoomOutAction:)];
	_zoomOutButton.bezelStyle = NSBezelStyleRounded;
	_zoomOutButton.toolTip = NSLocalizedString(@"Zoom Out", @"Tooltip for the zoom-out button.");

	_zoomLabelButton = [NSButton buttonWithTitle:@"100%"
										  target:self
										  action:@selector(zoomActualSizeAction:)];
	_zoomLabelButton.bezelStyle = NSBezelStyleRounded;
	_zoomLabelButton.font = [NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightMedium];
	_zoomLabelButton.toolTip = NSLocalizedString(@"Reset Zoom to 100% (Actual Page Size)", @"Tooltip for the zoom percentage button.");

	_zoomInButton = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"plus.magnifyingglass"
														accessibilityDescription:NSLocalizedString(@"Zoom In", @"Accessibility description for the zoom-in icon.")]
									   target:self
									   action:@selector(zoomInAction:)];
	_zoomInButton.bezelStyle = NSBezelStyleRounded;
	_zoomInButton.toolTip = NSLocalizedString(@"Zoom In", @"Tooltip for the zoom-in button.");

	// Page navigation controls
	_prevPageButton = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"chevron.left"
														  accessibilityDescription:NSLocalizedString(@"Previous Page", @"Accessibility description for the previous-page icon.")]
										 target:self
										 action:@selector(previousPageAction:)];
	_prevPageButton.bezelStyle = NSBezelStyleRounded;
	_prevPageButton.toolTip = NSLocalizedString(@"Previous Page", @"Tooltip for the previous-page button.");

	_pageNumberLabel = [NSTextField labelWithString:NSLocalizedString(@"Page 0 of 0", @"Viewer page-number placeholder before a report is rendered.")];
	_pageNumberLabel.font = [NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightRegular];
	_pageNumberLabel.textColor = [NSColor secondaryLabelColor];
	_pageNumberLabel.alignment = NSTextAlignmentCenter;

	_nextPageButton = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"chevron.right"
														  accessibilityDescription:NSLocalizedString(@"Next Page", @"Accessibility description for the next-page icon.")]
										 target:self
										 action:@selector(nextPageAction:)];
	_nextPageButton.bezelStyle = NSBezelStyleRounded;
	_nextPageButton.toolTip = NSLocalizedString(@"Next Page", @"Tooltip for the next-page button.");

	// Print & Export buttons with icons
	_printButton = [NSButton buttonWithTitle:NSLocalizedString(@"Print…", @"Viewer button that prints the rendered report.")
									  target:self
									  action:@selector(printReportAction:)];
	_printButton.image = [NSImage imageWithSystemSymbolName:@"printer"
								   accessibilityDescription:NSLocalizedString(@"Print Report", @"Accessibility description for the print button icon.")];
	_printButton.imagePosition = NSImageLeft;
	_printButton.bezelStyle = NSBezelStyleRounded;

	_exportButton = [NSButton buttonWithTitle:NSLocalizedString(@"Export…", @"Viewer button that exports the rendered report.")
									   target:self
									   action:@selector(exportReportAction:)];
	_exportButton.image = [NSImage imageWithSystemSymbolName:@"square.and.arrow.up"
									accessibilityDescription:NSLocalizedString(@"Export Report", @"Accessibility description for the export button icon.")];
	_exportButton.imagePosition = NSImageLeft;
	_exportButton.bezelStyle = NSBezelStyleRounded;

	NSView *spacerLeft = [[NSView alloc] initWithFrame:NSZeroRect];
	[spacerLeft setContentHuggingPriority:1 forOrientation:NSLayoutConstraintOrientationHorizontal];
	NSView *spacerRight = [[NSView alloc] initWithFrame:NSZeroRect];
	[spacerRight setContentHuggingPriority:1 forOrientation:NSLayoutConstraintOrientationHorizontal];

	NSStackView *topStack = [NSStackView stackViewWithViews:@[
		pageSizeLabel,
		_pageSizePopup,
		_refreshButton,
		_connectionButton,
		spacerLeft,
		_zoomOutButton,
		_zoomLabelButton,
		_zoomInButton,
		_prevPageButton,
		_pageNumberLabel,
		_nextPageButton,
		spacerRight,
		_printButton,
		_exportButton
	]];
	topStack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	topStack.spacing = 8;
	topStack.alignment = NSLayoutAttributeCenterY;
	topStack.edgeInsets = NSEdgeInsetsMake(4, 12, 4, 12);
	topStack.frame = topBar.bounds;
	topStack.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	[topBar addSubview:topStack];

	// 2. Center Framed Fixed-Size Paginated Report View
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

	// 3. Bottom Status Bar
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
	_statusLabel.font = [NSFont systemFontOfSize:12];
	_statusLabel.textColor = [NSColor secondaryLabelColor];
	_statusLabel.lineBreakMode = NSLineBreakByTruncatingTail;

	_paperStatusLabel = [NSTextField labelWithString:[[NSString alloc] initWithFormat:NSLocalizedString(@"Rendered Page Size: %@", @"Viewer status line. %@ is a paper name such as A4."), [MTPaper displayNameForPaperType:_renderedPaperType]]];
	_paperStatusLabel.font = [NSFont systemFontOfSize:11 weight:NSFontWeightMedium];
	_paperStatusLabel.textColor = [NSColor secondaryLabelColor];

	NSView *statusSpacer = [[NSView alloc] initWithFrame:NSZeroRect];
	[statusSpacer setContentHuggingPriority:1 forOrientation:NSLayoutConstraintOrientationHorizontal];

	NSStackView *statusStack = [NSStackView stackViewWithViews:@[
		_spinner,
		_statusLabel,
		statusSpacer,
		_paperStatusLabel
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
	[root addSubview:_statusBarView];

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

- (void)reloadPreview {
	MADHeadlessDocument *doc = _document.headlessDocument;
	if (doc == nil || !doc.refreshed) {
		_pdfView.document = nil;
		_statusLabel.stringValue = NSLocalizedString(@"Not yet refreshed. Click “Refresh” to query the database and render the report.", @"Viewer status line before the first refresh. The quoted word matches the Refresh button.");
		_statusLabel.textColor = [NSColor secondaryLabelColor];
		[self updateZoomAndPageControls];
		return;
	}

	[doc setPaperType:_renderedPaperType];
	_renderedPaperSize = doc.paperSize;

	NSUInteger rowCount = [doc.dataTable numberOfRows];

	// Render PDF preview into a temporary file using the locked renderedPaperType
	NSString *tmpPDF = [NSTemporaryDirectory() stringByAppendingPathComponent:
						[NSString stringWithFormat:@"mad-preview-%@.pdf", NSUUID.UUID.UUIDString]];
	NSURL *tmpPDFURL = [NSURL fileURLWithPath:tmpPDF];
	Class<MADReportExporting> pdfCls = [MADReportExporterRegistry exporterClassForFormat:@"pdf"];
	if (pdfCls != Nil && [pdfCls isAvailable]) {
		id<MADReportExporting> pdfExporter = [[(Class)pdfCls alloc] init];
		NSError *pdfErr = nil;
		if ([pdfExporter exportDocument:doc toURL:tmpPDFURL options:MADReportExportOptionsNone error:&pdfErr]) {
			PDFDocument *pdfDoc = [[PDFDocument alloc] initWithURL:tmpPDFURL];
			_pdfView.autoScales = NO;
			_pdfView.document = pdfDoc;
			_pdfView.scaleFactor = _zoomScale;
		}
		[[NSFileManager defaultManager] removeItemAtURL:tmpPDFURL error:NULL];
	}

	NSUInteger pageCount = _pdfView.document ? _pdfView.document.pageCount : 0;
	_statusLabel.stringValue = [MADMacViewerViewController statusMessageForPageCount:pageCount
																			rowCount:rowCount];
	_statusLabel.textColor = [NSColor systemGreenColor];
	[self updateZoomAndPageControls];
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
	for (NSString *fmt in preferredOrder) {
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
		id<MADReportExporting> exporter = [[(Class)cls alloc] init];
		NSError *err = nil;
		if (![exporter exportDocument:strongSelf.document.headlessDocument
								toURL:panel.URL
							  options:MADReportExportOptionsNone
								error:&err]) {
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
	if (_pdfView.document == nil) {
		[self refreshReportAction:nil];
		return;
	}
	NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
	[_pdfView printWithInfo:printInfo autoRotate:YES];
}

@end
