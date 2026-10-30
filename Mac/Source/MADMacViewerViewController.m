//
//  MADMacViewerViewController.m
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMacViewerViewController.h"
#import "MADMacDocument.h"

#import <MAD/MAD.h>
#import <MADSqlite3/MADDataTableFast.h>
#import <Quartz/Quartz.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

static const CGFloat kViewerTopToolbarHeight = 40.0;
static const CGFloat kViewerBottomStatusBarHeight = 28.0;

@interface MADMacViewerViewController ()

@property (nonatomic, strong, readwrite) NSButton *refreshButton;
@property (nonatomic, strong, readwrite) NSButton *exportButton;
@property (nonatomic, strong, readwrite) NSButton *printButton;
@property (nonatomic, strong, readwrite) NSPopUpButton *pageSizePopup;
@property (nonatomic, strong, readwrite) NSPopUpButton *exportFormatPopup;
@property (nonatomic, strong, readwrite) PDFView *pdfView;
@property (nonatomic, strong, readwrite) NSView *statusBarView;
@property (nonatomic, strong, readwrite) NSTextField *statusLabel;

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
		? @"1 page"
		: [NSString stringWithFormat:@"%lu pages", (unsigned long)pageCount];
	NSString *rowText = (rowCount == 1)
		? @"1 cached row"
		: [NSString stringWithFormat:@"%lu cached rows", (unsigned long)rowCount];
	return [NSString stringWithFormat:@"Rendered %@ from %@.", pageText, rowText];
}

+ (NSString *)friendlyTitleForExporterFormat:(NSString *)formatName extension:(NSString *)ext {
	if ([formatName isEqualToString:@"pdf"]) return [NSString stringWithFormat:@"PDF Document (.%@)", ext];
	if ([formatName isEqualToString:@"html"]) return [NSString stringWithFormat:@"HTML Page (.%@)", ext];
	if ([formatName isEqualToString:@"html-flow"]) return [NSString stringWithFormat:@"HTML Flow (.%@)", ext];
	if ([formatName isEqualToString:@"csv"]) return [NSString stringWithFormat:@"CSV Spreadsheet (.%@)", ext];
	if ([formatName isEqualToString:@"json"]) return [NSString stringWithFormat:@"JSON Data (.%@)", ext];
	if ([formatName isEqualToString:@"json-report"]) return [NSString stringWithFormat:@"JSON Full Report (.%@)", ext];
	if ([formatName isEqualToString:@"text"]) return [NSString stringWithFormat:@"Plain Text (.%@)", ext];
	return [NSString stringWithFormat:@"%@ (.%@)", formatName.uppercaseString, ext];
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

	NSTextField *pageSizeLabel = [NSTextField labelWithString:@"Page Size:"];
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

	_refreshButton = [NSButton buttonWithTitle:@"Refresh"
										target:self
										action:@selector(refreshReportAction:)];
	_refreshButton.image = [NSImage imageWithSystemSymbolName:@"arrow.clockwise"
									 accessibilityDescription:@"Refresh Report"];
	_refreshButton.imagePosition = NSImageLeft;
	_refreshButton.bezelStyle = NSBezelStyleRounded;

	// Zoom controls
	_zoomOutButton = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"minus.magnifyingglass"
														 accessibilityDescription:@"Zoom Out"]
										target:self
										action:@selector(zoomOutAction:)];
	_zoomOutButton.bezelStyle = NSBezelStyleRounded;
	_zoomOutButton.toolTip = @"Zoom Out";

	_zoomLabelButton = [NSButton buttonWithTitle:@"100%"
										  target:self
										  action:@selector(zoomActualSizeAction:)];
	_zoomLabelButton.bezelStyle = NSBezelStyleRounded;
	_zoomLabelButton.font = [NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightMedium];
	_zoomLabelButton.toolTip = @"Reset Zoom to 100% (Actual Page Size)";

	_zoomInButton = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"plus.magnifyingglass"
														accessibilityDescription:@"Zoom In"]
									   target:self
									   action:@selector(zoomInAction:)];
	_zoomInButton.bezelStyle = NSBezelStyleRounded;
	_zoomInButton.toolTip = @"Zoom In";

	// Page navigation controls
	_prevPageButton = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"chevron.left"
														  accessibilityDescription:@"Previous Page"]
										 target:self
										 action:@selector(previousPageAction:)];
	_prevPageButton.bezelStyle = NSBezelStyleRounded;
	_prevPageButton.toolTip = @"Previous Page";

	_pageNumberLabel = [NSTextField labelWithString:@"Page 0 of 0"];
	_pageNumberLabel.font = [NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightRegular];
	_pageNumberLabel.textColor = [NSColor secondaryLabelColor];
	_pageNumberLabel.alignment = NSTextAlignmentCenter;

	_nextPageButton = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"chevron.right"
														  accessibilityDescription:@"Next Page"]
										 target:self
										 action:@selector(nextPageAction:)];
	_nextPageButton.bezelStyle = NSBezelStyleRounded;
	_nextPageButton.toolTip = @"Next Page";

	// Print & Export buttons with icons
	_printButton = [NSButton buttonWithTitle:@"Print…"
									  target:self
									  action:@selector(printReportAction:)];
	_printButton.image = [NSImage imageWithSystemSymbolName:@"printer"
								   accessibilityDescription:@"Print Report"];
	_printButton.imagePosition = NSImageLeft;
	_printButton.bezelStyle = NSBezelStyleRounded;

	_exportButton = [NSButton buttonWithTitle:@"Export…"
									   target:self
									   action:@selector(exportReportAction:)];
	_exportButton.image = [NSImage imageWithSystemSymbolName:@"square.and.arrow.up"
									accessibilityDescription:@"Export Report"];
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

	_statusLabel = [NSTextField labelWithString:@"Not yet refreshed. Click “Refresh” to query the database and render the report."];
	_statusLabel.font = [NSFont systemFontOfSize:12];
	_statusLabel.textColor = [NSColor secondaryLabelColor];
	_statusLabel.lineBreakMode = NSLineBreakByTruncatingTail;

	_paperStatusLabel = [NSTextField labelWithString:[NSString stringWithFormat:@"Rendered Page Size: %@", [MTPaper displayNameForPaperType:_renderedPaperType]]];
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
		_pageNumberLabel.stringValue = @"Page 0 of 0";
		_prevPageButton.enabled = NO;
		_nextPageButton.enabled = NO;
	} else {
		PDFPage *curPage = _pdfView.currentPage;
		NSUInteger curIdx = curPage != nil ? [pdfDoc indexForPage:curPage] + 1 : 1;
		_pageNumberLabel.stringValue = [NSString stringWithFormat:@"Page %lu of %lu",
										(unsigned long)curIdx,
										(unsigned long)totalPages];
		_prevPageButton.enabled = _pdfView.canGoToPreviousPage;
		_nextPageButton.enabled = _pdfView.canGoToNextPage;
	}
	_paperStatusLabel.stringValue = [NSString stringWithFormat:@"Rendered Page Size: %@",
									 [MTPaper displayNameForPaperType:_renderedPaperType]];
}

#pragma mark - Refresh & Render

- (void)refreshReportAction:(id) __unused sender {
	MADHeadlessDocument *doc = _document.headlessDocument;
	if (doc == nil) return;

	_renderedPaperType = _selectedPaperType ?: MTPaperTypeLetter;
	[doc setPaperType:_renderedPaperType];
	_renderedPaperSize = doc.paperSize;

	[_spinner startAnimation:nil];
	_statusLabel.stringValue = @"Executing SQL query and formatting report pages…";
	_statusLabel.textColor = [NSColor secondaryLabelColor];

	__weak typeof(self) weakSelf = self;
	[_document refreshDataWithPassword:nil completion:^(BOOL success, NSError * _Nullable error) {
		__strong typeof(weakSelf) strongSelf = weakSelf;
		if (!strongSelf) return;
		[strongSelf.spinner stopAnimation:nil];
		if (!success) {
			strongSelf.statusLabel.stringValue = error.localizedDescription ?: @"Refresh failed.";
			strongSelf.statusLabel.textColor = [NSColor systemRedColor];
			return;
		}
		[strongSelf reloadPreview];
	}];
}

- (void)reloadPreview {
	MADHeadlessDocument *doc = _document.headlessDocument;
	if (doc == nil || !doc.refreshed) {
		_pdfView.document = nil;
		_statusLabel.stringValue = @"Not yet refreshed. Click “Refresh” to query the database and render the report.";
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
	NSTextField *formatLabel = [NSTextField labelWithString:@"Export Format:"];
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
		_renderedPaperType = _selectedPaperType ?: MTPaperTypeLetter;
		[doc setPaperType:_renderedPaperType];
		_renderedPaperSize = doc.paperSize;
		__weak typeof(self) weakSelf = self;
		[_document refreshDataWithPassword:nil completion:^(BOOL success, NSError * _Nullable error) {
			if (!success) {
				if (error) [NSApp presentError:error];
				return;
			}
			[weakSelf reloadPreview];
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
			strongSelf.statusLabel.stringValue = [NSString stringWithFormat:@"Exported %@ to %@",
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
