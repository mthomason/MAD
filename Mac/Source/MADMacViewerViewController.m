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
#import <WebKit/WebKit.h>

@interface MADMacViewerViewController () <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, strong) NSSegmentedControl *modeSegmented;
@property (nonatomic, strong) NSPopUpButton *exportFormatPopup;
@property (nonatomic, strong) NSProgressIndicator *spinner;
@property (nonatomic, strong) NSTextField *statusLabel;

@property (nonatomic, strong) NSTabView *contentTabView;
@property (nonatomic, strong) PDFView *pdfView;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) NSTableView *dataTableView;

@property (nonatomic, copy) NSArray<Class<MADReportExporting>> *exporterClasses;

@end

@implementation MADMacViewerViewController

- (instancetype)initWithDocument:(MADMacDocument *)document {
	if (self = [super initWithNibName:nil bundle:nil]) {
		_document = document;
		_exporterClasses = [MADReportExporterRegistry registeredExporterClasses] ?: @[];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView {
	NSView *root = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 1180, 740)];
	root.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

	NSButton *refreshBtn = [NSButton buttonWithTitle:@"Refresh Report Data"
											  target:self
											  action:@selector(refreshReportAction:)];

	_modeSegmented = [NSSegmentedControl segmentedControlWithLabels:@[
		@"Paginated PDF Preview",
		@"HTML Preview",
		@"Cached Result Rows"
	] trackingMode:NSSegmentSwitchTrackingSelectOne target:self action:@selector(modeSegmentChanged:)];
	_modeSegmented.selectedSegment = 0;

	_exportFormatPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 180, 26) pullsDown:NO];
	NSInteger pdfIdx = 0;
	for (NSUInteger i = 0; i < _exporterClasses.count; i++) {
		Class<MADReportExporting> cls = _exporterClasses[i];
		NSString *label = [NSString stringWithFormat:@"%@ (.%@)", [cls formatName], [cls fileExtension]];
		[_exportFormatPopup addItemWithTitle:label];
		if ([[cls formatName] isEqualToString:@"pdf"]) {
			pdfIdx = (NSInteger)i;
		}
	}
	if (_exportFormatPopup.numberOfItems > pdfIdx) {
		[_exportFormatPopup selectItemAtIndex:pdfIdx];
	}

	NSButton *exportBtn = [NSButton buttonWithTitle:@"Export…"
											 target:self
											 action:@selector(exportReportAction:)];
	NSButton *printBtn = [NSButton buttonWithTitle:@"Print…"
											target:self
											action:@selector(printReportAction:)];

	_spinner = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 16, 16)];
	_spinner.style = NSProgressIndicatorStyleSpinning;
	_spinner.displayedWhenStopped = NO;

	_statusLabel = [NSTextField labelWithString:@"Click 'Refresh Report Data' to query the database and render the report."];
	_statusLabel.font = [NSFont systemFontOfSize:12.0];
	_statusLabel.textColor = [NSColor secondaryLabelColor];
	_statusLabel.lineBreakMode = NSLineBreakByTruncatingTail;

	NSStackView *topBar = [NSStackView stackViewWithViews:@[
		refreshBtn, _modeSegmented, _exportFormatPopup, exportBtn, printBtn, _spinner, _statusLabel
	]];
	topBar.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	topBar.spacing = 10.0;
	topBar.translatesAutoresizingMaskIntoConstraints = NO;

	_contentTabView = [[NSTabView alloc] initWithFrame:NSMakeRect(0, 0, 1180, 690)];
	_contentTabView.tabViewType = NSNoTabsBezelBorder;
	_contentTabView.translatesAutoresizingMaskIntoConstraints = NO;

	// Tab 0: PDFView
	NSTabViewItem *pdfTab = [[NSTabViewItem alloc] initWithIdentifier:@"pdf"];
	_pdfView = [[PDFView alloc] initWithFrame:NSMakeRect(0, 0, 1160, 680)];
	_pdfView.autoScales = YES;
	_pdfView.displayMode = kPDFDisplaySinglePageContinuous;
	_pdfView.displaysPageBreaks = YES;
	pdfTab.view = _pdfView;
	[_contentTabView addTabViewItem:pdfTab];

	// Tab 1: WKWebView
	NSTabViewItem *htmlTab = [[NSTabViewItem alloc] initWithIdentifier:@"html"];
	_webView = [[WKWebView alloc] initWithFrame:NSMakeRect(0, 0, 1160, 680)];
	htmlTab.view = _webView;
	[_contentTabView addTabViewItem:htmlTab];

	// Tab 2: NSTableView
	NSTabViewItem *tableTab = [[NSTabViewItem alloc] initWithIdentifier:@"table"];
	_dataTableView = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, 1160, 680)];
	_dataTableView.usesAlternatingRowBackgroundColors = YES;
	_dataTableView.rowHeight = 20.0;
	_dataTableView.delegate = self;
	_dataTableView.dataSource = self;
	NSScrollView *tableScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 1160, 680)];
	tableScroll.hasVerticalScroller = YES;
	tableScroll.hasHorizontalScroller = YES;
	tableScroll.documentView = _dataTableView;
	tableTab.view = tableScroll;
	[_contentTabView addTabViewItem:tableTab];

	[root addSubview:topBar];
	[root addSubview:_contentTabView];

	[NSLayoutConstraint activateConstraints:@[
		[topBar.topAnchor constraintEqualToAnchor:root.topAnchor constant:10],
		[topBar.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:12],
		[topBar.trailingAnchor constraintLessThanOrEqualToAnchor:root.trailingAnchor constant:-12],

		[_contentTabView.topAnchor constraintEqualToAnchor:topBar.bottomAnchor constant:10],
		[_contentTabView.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:12],
		[_contentTabView.trailingAnchor constraintEqualToAnchor:root.trailingAnchor constant:-12],
		[_contentTabView.bottomAnchor constraintEqualToAnchor:root.bottomAnchor constant:-12],
	]];

	self.view = root;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleDocumentRefresh:)
												 name:MADMacDocumentDidRefreshNotification
											   object:_document];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleDocumentMutate:)
												 name:MADMacDocumentDidMutateNotification
											   object:_document];
	[self reloadPreview];
}

- (void)handleDocumentRefresh:(NSNotification *) __unused note {
	[self reloadPreview];
}

- (void)handleDocumentMutate:(NSNotification *) __unused note {
	if (_document.headlessDocument.refreshed) {
		[self reloadPreview];
	}
}

- (void)modeSegmentChanged:(id) __unused sender {
	[_contentTabView selectTabViewItemAtIndex:_modeSegmented.selectedSegment];
}

- (void)reloadPreview {
	MADHeadlessDocument *headless = _document.headlessDocument;
	if (headless == nil || !headless.refreshed) {
		return;
	}

	// 1. Render PDF preview to a temporary file and load into PDFView
	NSString *tmpPDFPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
							[NSString stringWithFormat:@"mad-preview-%@.pdf", NSUUID.UUID.UUIDString]];
	NSURL *tmpPDFURL = [NSURL fileURLWithPath:tmpPDFPath];
	NSError *pdfErr = nil;
	if ([_document exportToURL:tmpPDFURL format:@"pdf" error:&pdfErr]) {
		PDFDocument *pdfDoc = [[PDFDocument alloc] initWithURL:tmpPDFURL];
		if (pdfDoc != nil) {
			_pdfView.document = pdfDoc;
		}
	}
	[[NSFileManager defaultManager] removeItemAtURL:tmpPDFURL error:NULL];

	// 2. Render HTML preview and load into WKWebView
	NSString *tmpHTMLPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
							 [NSString stringWithFormat:@"mad-preview-%@.html", NSUUID.UUID.UUIDString]];
	NSURL *tmpHTMLURL = [NSURL fileURLWithPath:tmpHTMLPath];
	NSError *htmlErr = nil;
	if ([_document exportToURL:tmpHTMLURL format:@"html" error:&htmlErr]) {
		NSString *htmlString = [NSString stringWithContentsOfURL:tmpHTMLURL encoding:NSUTF8StringEncoding error:NULL];
		if (htmlString.length > 0) {
			[_webView loadHTMLString:htmlString baseURL:nil];
		}
	}
	[[NSFileManager defaultManager] removeItemAtURL:tmpHTMLURL error:NULL];

	// 3. Reload NSTableView over MADDataTableFast
	while (_dataTableView.tableColumns.count > 0) {
		[_dataTableView removeTableColumn:_dataTableView.tableColumns.lastObject];
	}
	MADDataTableFast *dt = headless.dataTable;
	for (NSString *key in (dt.columnKeys ?: @[])) {
		NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:key];
		col.title = key;
		col.width = 140.0;
		[_dataTableView addTableColumn:col];
	}
	[_dataTableView reloadData];

	NSUInteger pageCount = _pdfView.document ? _pdfView.document.pageCount : 0;
	_statusLabel.textColor = [NSColor systemGreenColor];
	_statusLabel.stringValue = [NSString stringWithFormat:@"Rendered %lu page(s) from %lu cached row(s).",
								(unsigned long)pageCount,
								(unsigned long)[dt numberOfRows]];
}

- (void)refreshReportAction:(nullable id) __unused sender {
	[_spinner startAnimation:nil];
	_statusLabel.textColor = [NSColor secondaryLabelColor];
	_statusLabel.stringValue = @"Refreshing report data from database…";

	__weak typeof(self) weakSelf = self;
	[_document refreshDataWithPassword:nil completion:^(BOOL success, NSError * _Nullable error) {
		typeof(self) strongSelf = weakSelf;
		if (strongSelf == nil) return;
		[strongSelf.spinner stopAnimation:nil];
		if (success) {
			[strongSelf reloadPreview];
		} else {
			RptqDatabaseCredentals *cred = strongSelf.document.rptqQuery.inDatabase.ownedByUser;
			if (cred != nil && cred.host.length > 0) {
				[strongSelf promptForPasswordAndRetryWithUsername:(cred.dbname ?: cred.host)];
			} else {
				strongSelf.statusLabel.textColor = [NSColor systemRedColor];
				strongSelf.statusLabel.stringValue = error.localizedDescription ?: @"Refresh failed.";
			}
		}
	}];
}

- (void)promptForPasswordAndRetryWithUsername:(NSString *)username {
	NSAlert *alert = [[NSAlert alloc] init];
	alert.messageText = @"Database Password Required";
	alert.informativeText = [NSString stringWithFormat:@"Enter the password for database user '%@':", username];
	[alert addButtonWithTitle:@"Connect & Refresh"];
	[alert addButtonWithTitle:@"Cancel"];

	NSSecureTextField *pwField = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0, 0, 260, 24)];
	alert.accessoryView = pwField;

	if ([alert runModal] == NSAlertFirstButtonReturn) {
		NSString *password = pwField.stringValue ?: @"";
		[_spinner startAnimation:nil];
		__weak typeof(self) weakSelf = self;
		[_document refreshDataWithPassword:password completion:^(BOOL success, NSError * _Nullable error) {
			typeof(self) strongSelf = weakSelf;
			if (strongSelf == nil) return;
			[strongSelf.spinner stopAnimation:nil];
			if (success) {
				[strongSelf reloadPreview];
			} else {
				strongSelf.statusLabel.textColor = [NSColor systemRedColor];
				strongSelf.statusLabel.stringValue = error.localizedDescription ?: @"Refresh failed.";
			}
		}];
	}
}

- (void)exportReportAction:(nullable id) __unused sender {
	if (!_document.headlessDocument.refreshed) {
		_statusLabel.textColor = [NSColor systemOrangeColor];
		_statusLabel.stringValue = @"Refreshing data before exporting…";
		__weak typeof(self) weakSelf = self;
		[_document refreshDataWithPassword:nil completion:^(BOOL success, NSError * _Nullable __unused error) {
			if (success) {
				[weakSelf performExportPanel];
			}
		}];
		return;
	}
	[self performExportPanel];
}

- (void)performExportPanel {
	NSInteger idx = _exportFormatPopup.indexOfSelectedItem;
	if (idx < 0 || (NSUInteger)idx >= _exporterClasses.count) return;
	Class<MADReportExporting> cls = _exporterClasses[(NSUInteger)idx];
	NSString *format = [cls formatName];
	NSString *ext = [cls fileExtension];

	NSSavePanel *panel = [NSSavePanel savePanel];
	panel.title = [NSString stringWithFormat:@"Export Report as %@", [format uppercaseString]];
	NSString *baseName = _document.fileURL.lastPathComponent.stringByDeletingPathExtension ?: @"Report";
	panel.nameFieldStringValue = [NSString stringWithFormat:@"%@.%@", baseName, ext];
	if ([panel runModal] != NSModalResponseOK || panel.URL == nil) return;

	NSError *exportError = nil;
	if ([_document exportToURL:panel.URL format:format error:&exportError]) {
		_statusLabel.textColor = [NSColor systemGreenColor];
		_statusLabel.stringValue = [NSString stringWithFormat:@"Exported %@ to %@", [format uppercaseString], panel.URL.lastPathComponent];
	} else {
		_statusLabel.textColor = [NSColor systemRedColor];
		_statusLabel.stringValue = exportError.localizedDescription ?: @"Export failed.";
	}
}

- (void)printReportAction:(nullable id) __unused sender {
	if (_pdfView.document == nil) {
		[self reloadPreview];
	}
	PDFDocument *pdfDoc = _pdfView.document;
	if (pdfDoc == nil) return;

	NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
	NSPrintOperation *op = [pdfDoc printOperationForPrintInfo:printInfo
												  scalingMode:kPDFPrintPageScaleDownToFit
												   autoRotate:YES];
	if (op != nil && self.view.window != nil) {
		[op runOperationModalForWindow:self.view.window delegate:nil didRunSelector:NULL contextInfo:NULL];
	}
}

#pragma mark - NSTableViewDataSource & Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *) __unused tableView {
	MADDataTableFast *dt = _document.headlessDocument.dataTable;
	return (NSInteger)[dt numberOfRows];
}

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
	MADDataTableFast *dt = _document.headlessDocument.dataTable;
	NSDictionary *rowDict = [dt dataForRow:(NSUInteger)row error:NULL];
	id val = tableColumn.identifier ? rowDict[tableColumn.identifier] : nil;
	NSString *text = (val != nil && val != [NSNull null]) ? [val description] : @"";

	NSTextField *cell = [tableView makeViewWithIdentifier:@"ViewerRowCell" owner:self];
	if (cell == nil) {
		cell = [NSTextField labelWithString:text];
		cell.identifier = @"ViewerRowCell";
		cell.font = [NSFont systemFontOfSize:12.0];
		cell.lineBreakMode = NSLineBreakByTruncatingTail;
	} else {
		cell.stringValue = text;
	}
	return cell;
}

@end
