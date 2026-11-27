//
//  MADMacAppDelegate.m
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMacAppDelegate.h"
#import "MADMacAboutWindowController.h"
#import "MADMacConnectionWindowController.h"
#import "MADMacDocument.h"
#import "MADMacDocumentController.h"
#import "MADMacWindowController.h"
#import "MADMacDesignerViewController.h"
#import "MADMacTipBar.h"
#import "MADStoreLegacyConverter.h"

#import <MAD/MAD.h>
#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADURLFactory.h>
#import <MADAPI/MADDatabaseDriverRegistry.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <MADMySQL/MADDatabaseConnectionMySql.h>
#import <MADTdsClient/MADDatabaseConnectionSQLServer.h>
#import <MADPostgres/MADDatabaseConnectionPostgres.h>

@interface MADMacAppDelegate () <NSMenuDelegate>

@property (nonatomic, strong, nullable) MADMacConnectionWindowController *connectionWindowController;
@property (nonatomic, strong, readwrite) MADMacAboutWindowController *aboutWindowController;
@property (nonatomic, strong, nullable) NSMenu *openRecentMenu;

@end

static void MADSetMenuSymbol(NSMenuItem *item, NSString *symbolName) {
	if (@available(macOS 11.0, *)) {
		NSImage *image = [NSImage imageWithSystemSymbolName:symbolName accessibilityDescription:nil];
		if (image != nil) item.image = image;
	}
}

static NSMenuItem *MADAddMenuItem(NSMenu *menu, NSString *title, SEL action, NSString *key, id target) {
	NSMenuItem *item = [menu addItemWithTitle:title action:action keyEquivalent:key ?: @""];
	item.target = target;
	return item;
}

@implementation MADMacAppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *) __unused notification {
	(void)[[MADMacDocumentController alloc] init];

	// Ensure driver, exporter, and legacy store converter classes are linked and registered.
	[MADLegacyStoreConversion setConverter:[[MADStoreLegacyConverter alloc] init]];
	(void)[MADDatabaseConnectionSqlite3 class];
	(void)[MADDatabaseConnectionMySql class];
	(void)[MADDatabaseConnectionSQLServer class];
	(void)[MADDatabaseConnectionPostgres class];

	[self buildMainMenu];
}

- (void)applicationDidFinishLaunching:(NSNotification *) __unused notification {
	[NSApp activateIgnoringOtherApps:YES];
	if ([NSDocumentController sharedDocumentController].documents.count == 0) {
		[[NSDocumentController sharedDocumentController] openDocument:nil];
	}
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *) __unused sender {
	return NO;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *) __unused sender hasVisibleWindows:(BOOL)flag {
	if (!flag) {
		[[NSDocumentController sharedDocumentController] openDocument:nil];
	}
	return YES;
}

#pragma mark - Main Menu

- (void)buildMainMenu {
	NSMenu *menubar = [[NSMenu alloc] init];
	[NSApp setMainMenu:menubar];

	// App Menu
	NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:appMenuItem];
	NSMenu *appMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"MAD Designer", @"Application name. A brand; do not translate.")];
	NSMenuItem *aboutItem = MADAddMenuItem(appMenu, NSLocalizedString(@"About MAD Designer", @"Application menu item that opens the About window. MAD Designer is a brand."), @selector(showAboutWindow:), @"", self);
	MADSetMenuSymbol(aboutItem, @"info.circle");
	[appMenu addItem:[NSMenuItem separatorItem]];
	MADAddMenuItem(appMenu, NSLocalizedString(@"Hide MAD Designer", @"Application menu item that hides the app. MAD Designer is a brand."), @selector(hide:), @"h", nil);
	NSMenuItem *hideOthers = MADAddMenuItem(appMenu, NSLocalizedString(@"Hide Others", @"Application menu item that hides every other app."), @selector(hideOtherApplications:), @"h", nil);
	hideOthers.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagOption;
	MADAddMenuItem(appMenu, NSLocalizedString(@"Show All", @"Application menu item that shows all hidden apps."), @selector(unhideAllApplications:), @"", nil);
	[appMenu addItem:[NSMenuItem separatorItem]];
	MADAddMenuItem(appMenu, NSLocalizedString(@"Quit MAD Designer", @"Application menu item that quits the app. MAD Designer is a brand."), @selector(terminate:), @"q", nil);
	[appMenuItem setSubmenu:appMenu];

	// File Menu
	NSMenuItem *fileMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:fileMenuItem];
	NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"File", @"File menu title.")];
	fileMenu.delegate = self;
	NSMenuItem *newItem = MADAddMenuItem(fileMenu, NSLocalizedString(@"New…", @"File menu item that starts a new report; offers the report type."), @selector(newDocumentWithChooser:), @"n", self);
	MADSetMenuSymbol(newItem, @"doc.badge.plus");
	NSMenuItem *newComposition = MADAddMenuItem(fileMenu, NSLocalizedString(@"New Composition…", @"File menu item that starts a new composition from existing reports."), @selector(newCompositionDocument:), @"", self);
	MADSetMenuSymbol(newComposition, @"square.stack.3d.up");
	NSMenuItem *openItem = MADAddMenuItem(fileMenu, NSLocalizedString(@"Open…", @"File menu item that opens an existing report."), @selector(openDocument:), @"o", nil);
	MADSetMenuSymbol(openItem, @"folder");
	NSMenuItem *openRecentItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open Recent", @"File submenu title for recently opened reports.") action:nil keyEquivalent:@""];
	NSMenu *openRecent = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Open Recent", @"File submenu title for recently opened reports.")];
	self.openRecentMenu = openRecent;
	openRecentItem.submenu = openRecent;
	MADSetMenuSymbol(openRecentItem, @"clock.arrow.circlepath");
	[fileMenu addItem:openRecentItem];
	[fileMenu addItem:[NSMenuItem separatorItem]];
	NSMenuItem *saveItem = MADAddMenuItem(fileMenu, NSLocalizedString(@"Save", @"File menu item that saves the report."), @selector(saveDocument:), @"s", nil);
	MADSetMenuSymbol(saveItem, @"square.and.arrow.down");
	MADAddMenuItem(fileMenu, NSLocalizedString(@"Save As…", @"File menu item that saves the report under a new name."), @selector(saveDocumentAs:), @"S", nil);
	MADAddMenuItem(fileMenu, NSLocalizedString(@"Rename…", @"File menu item that renames the report's file."), @selector(renameDocument:), @"", nil);
	[fileMenu addItem:[NSMenuItem separatorItem]];
	MADAddMenuItem(fileMenu, NSLocalizedString(@"Convert to Composition…", @"File menu item that converts the current standard report into a one-child composition."), @selector(convertCurrentDocumentToComposition:), @"", self);
	[fileMenu addItem:[NSMenuItem separatorItem]];
	NSMenuItem *exportItem = MADAddMenuItem(fileMenu, NSLocalizedString(@"Export Report…", @"File menu item that exports the rendered report."), @selector(exportCurrentReport:), @"e", self);
	MADSetMenuSymbol(exportItem, @"square.and.arrow.up");
	NSMenuItem *printItem = MADAddMenuItem(fileMenu, NSLocalizedString(@"Print…", @"File menu item that prints the rendered report."), @selector(printCurrentReport:), @"p", self);
	MADSetMenuSymbol(printItem, @"printer");
	[fileMenu addItem:[NSMenuItem separatorItem]];
	MADAddMenuItem(fileMenu, NSLocalizedString(@"Close", @"File menu item that closes the window."), @selector(performClose:), @"w", nil);
	[fileMenuItem setSubmenu:fileMenu];
	[self rebuildOpenRecentMenu];

	// Edit Menu
	NSMenuItem *editMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:editMenuItem];
	NSMenu *editMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Edit", @"Edit menu title.")];
	MADAddMenuItem(editMenu, NSLocalizedString(@"Undo", @"Edit menu item that undoes the last change."), NSSelectorFromString(@"undo:"), @"z", nil);
	MADAddMenuItem(editMenu, NSLocalizedString(@"Redo", @"Edit menu item that redoes the last undone change."), NSSelectorFromString(@"redo:"), @"Z", nil);
	[editMenu addItem:[NSMenuItem separatorItem]];
	MADAddMenuItem(editMenu, NSLocalizedString(@"Cut", @"Edit menu item that cuts the selection."), @selector(cut:), @"x", nil);
	MADAddMenuItem(editMenu, NSLocalizedString(@"Copy", @"Edit menu item that copies the selection."), @selector(copy:), @"c", nil);
	MADAddMenuItem(editMenu, NSLocalizedString(@"Paste", @"Edit menu item that pastes the clipboard."), @selector(paste:), @"v", nil);
	MADAddMenuItem(editMenu, NSLocalizedString(@"Duplicate", @"Edit menu item that duplicates the selection."), NSSelectorFromString(@"duplicate:"), @"d", nil);
	MADAddMenuItem(editMenu, NSLocalizedString(@"Delete", @"Edit menu item that deletes the selection."), @selector(delete:), @"", nil);
	MADAddMenuItem(editMenu, NSLocalizedString(@"Select All", @"Edit menu item that selects everything."), @selector(selectAll:), @"a", nil);
	[editMenuItem setSubmenu:editMenu];

	// Insert Menu
	NSMenuItem *insertMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:insertMenuItem];
	NSMenu *insertMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Insert", @"Insert menu title.")];
	NSMenuItem *labelItem = MADAddMenuItem(insertMenu, NSLocalizedString(@"Static Label", @"Insert menu item that inserts a static label."), @selector(insertElementFromMenu:), @"1", nil);
	labelItem.tag = MADMacPaletteElementKindLabel;
	MADSetMenuSymbol(labelItem, @"textformat");
	NSMenuItem *dataItem = MADAddMenuItem(insertMenu, NSLocalizedString(@"Data Field", @"Insert menu item that inserts a field bound to the query."), @selector(insertElementFromMenu:), @"2", nil);
	dataItem.tag = MADMacPaletteElementKindDataField;
	MADSetMenuSymbol(dataItem, @"tablecells");
	NSMenuItem *aggregateItem = MADAddMenuItem(insertMenu, NSLocalizedString(@"Aggregate", @"Insert menu item that inserts an aggregate."), @selector(insertElementFromMenu:), @"3", nil);
	aggregateItem.tag = MADMacPaletteElementKindAggregate;
	MADSetMenuSymbol(aggregateItem, @"sum");
	[insertMenu addItem:[NSMenuItem separatorItem]];
	NSMenuItem *imageItem = MADAddMenuItem(insertMenu, NSLocalizedString(@"Image", @"Insert menu item that inserts an image."), @selector(insertElementFromMenu:), @"4", nil);
	imageItem.tag = MADMacPaletteElementKindImage;
	MADSetMenuSymbol(imageItem, @"photo");
	NSMenuItem *barcodeItem = MADAddMenuItem(insertMenu, NSLocalizedString(@"Barcode", @"Insert menu item that inserts a barcode."), @selector(insertElementFromMenu:), @"5", nil);
	barcodeItem.tag = MADMacPaletteElementKindBarcode;
	MADSetMenuSymbol(barcodeItem, @"barcode");
	[insertMenu addItem:[NSMenuItem separatorItem]];
	NSMenuItem *ruleItem = MADAddMenuItem(insertMenu, NSLocalizedString(@"Horizontal Rule", @"Insert menu item that inserts a horizontal rule."), @selector(insertElementFromMenu:), @"6", nil);
	ruleItem.tag = MADMacPaletteElementKindLineRule;
	MADSetMenuSymbol(ruleItem, @"minus");
	for (NSMenuItem *item in insertMenu.itemArray) {
		if (item.isSeparatorItem) continue;
		item.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagOption;
	}
	[insertMenuItem setSubmenu:insertMenu];

	// Format Menu
	NSMenuItem *formatMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:formatMenuItem];
	NSMenu *formatMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Format", @"Format menu title.")];
	NSMenuItem *fitItem = MADAddMenuItem(formatMenu, NSLocalizedString(@"Size to Fit", @"Format menu item that resizes the selection to its text."), @selector(formatSizeToFit:), @"", nil);
	MADSetMenuSymbol(fitItem, @"arrow.up.left.and.arrow.down.right");
	NSMenuItem *alignParent = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Align", @"Format submenu title for element alignment.") action:nil keyEquivalent:@""];
	NSMenu *alignMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Align", @"Format submenu title for element alignment.")];
	NSArray<NSString *> *alignTitles = @[
		NSLocalizedString(@"Align Left", @"Format menu item that aligns selected elements to the left."),
		NSLocalizedString(@"Align Center", @"Format menu item that centers selected elements horizontally."),
		NSLocalizedString(@"Align Right", @"Format menu item that aligns selected elements to the right."),
		NSLocalizedString(@"Align Top", @"Format menu item that aligns selected elements to the top."),
		NSLocalizedString(@"Align Middle", @"Format menu item that centers selected elements vertically."),
		NSLocalizedString(@"Align Bottom", @"Format menu item that aligns selected elements to the bottom."),
	];
	for (NSUInteger i = 0; i < alignTitles.count; i++) {
		NSMenuItem *item = MADAddMenuItem(alignMenu, alignTitles[i], @selector(alignSelectedElementsFromMenu:), @"", nil);
		item.tag = (NSInteger)i;
	}
	alignParent.submenu = alignMenu;
	[formatMenu addItem:alignParent];
	[formatMenu addItem:[NSMenuItem separatorItem]];
	MADAddMenuItem(formatMenu, NSLocalizedString(@"Bold", @"Format menu item that toggles bold text."), @selector(toggleBoldStyle:), @"b", nil);
	MADAddMenuItem(formatMenu, NSLocalizedString(@"Italic", @"Format menu item that toggles italic text."), @selector(toggleItalicStyle:), @"i", nil);
	MADAddMenuItem(formatMenu, NSLocalizedString(@"Underline", @"Format menu item that toggles underlined text."), @selector(toggleUnderlineStyle:), @"u", nil);
	[formatMenuItem setSubmenu:formatMenu];

	// Query Menu
	NSMenuItem *queryMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:queryMenuItem];
	NSMenu *queryMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Query", @"Query menu title.")];
	MADAddMenuItem(queryMenu, NSLocalizedString(@"Add Table to Query", @"Query menu item that adds the selected database table."), @selector(queryAddSelectedTable:), @"t", nil);
	MADAddMenuItem(queryMenu, NSLocalizedString(@"Add Source Query…", @"Query menu item that adds a source query from a connection."), @selector(queryAddSource:), @"", nil);
	MADAddMenuItem(queryMenu, NSLocalizedString(@"Import Report…", @"Query menu item that imports an existing report as a child."), @selector(queryImportReport:), @"", nil);
	MADAddMenuItem(queryMenu, NSLocalizedString(@"Create Root Query", @"Query menu item that creates the composed root query."), @selector(queryCreateRoot:), @"", nil);
	[queryMenu addItem:[NSMenuItem separatorItem]];
	MADAddMenuItem(queryMenu, NSLocalizedString(@"Outputs…", @"Query menu item that edits the composed root's outputs."), @selector(queryShowOutputs:), @"", nil);
	MADAddMenuItem(queryMenu, NSLocalizedString(@"Filters…", @"Query menu item that edits the WHERE filters."), @selector(queryShowFilters:), @"", nil);
	MADAddMenuItem(queryMenu, NSLocalizedString(@"Groupings…", @"Query menu item that edits the GROUP BY groupings."), @selector(queryShowGroupings:), @"", nil);
	[queryMenu addItem:[NSMenuItem separatorItem]];
	MADAddMenuItem(queryMenu, NSLocalizedString(@"Rename Query…", @"Query menu item that renames the selected query."), @selector(queryRename:), @"", nil);
	MADAddMenuItem(queryMenu, NSLocalizedString(@"Arrange Tables", @"Query menu item that lays the table cards out automatically."), @selector(queryArrangeTables:), @"", nil);
	[queryMenu addItem:[NSMenuItem separatorItem]];
	MADAddMenuItem(queryMenu, NSLocalizedString(@"Database Connection…", @"Query menu item that edits the database connection."), @selector(queryEditConnection:), @"", nil);
	[queryMenuItem setSubmenu:queryMenu];

	// Report Menu
	NSMenuItem *reportMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:reportMenuItem];
	NSMenu *reportMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Report", @"Report menu title.")];
	NSMenuItem *refreshItem = MADAddMenuItem(reportMenu, NSLocalizedString(@"Refresh Report Data", @"Report menu item that re-runs the query and re-renders the report."), @selector(refreshCurrentReport:), @"r", self);
	MADSetMenuSymbol(refreshItem, @"arrow.clockwise");
	[reportMenu addItem:[NSMenuItem separatorItem]];
	NSMenuItem *paperParent = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Page Size", @"Report submenu title for paper size.") action:nil keyEquivalent:@""];
	NSMenu *paperMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Page Size", @"Report submenu title for paper size.")];
	for (NSNumber *typeNum in [MTPaper standardPaperTypes]) {
		MTPaperType type = (MTPaperType)typeNum.integerValue;
		NSMenuItem *item = MADAddMenuItem(paperMenu, [MTPaper displayNameForPaperType:type], @selector(selectReportPaperTypeFromMenu:), @"", nil);
		item.representedObject = typeNum;
	}
	paperParent.submenu = paperMenu;
	[reportMenu addItem:paperParent];
	[reportMenu addItem:[NSMenuItem separatorItem]];
	MADAddMenuItem(reportMenu, NSLocalizedString(@"Export Report…", @"Report menu item that exports the rendered report."), @selector(exportCurrentReport:), @"e", self);
	MADAddMenuItem(reportMenu, NSLocalizedString(@"Print…", @"Report menu item that prints the rendered report."), @selector(printCurrentReport:), @"p", self);
	[reportMenu addItem:[NSMenuItem separatorItem]];
	MADAddMenuItem(reportMenu, NSLocalizedString(@"Database Connection…", @"Report menu item that edits the database connection."), @selector(editCurrentDatabaseConnection:), @"", self);
	[reportMenuItem setSubmenu:reportMenu];

	// View Menu
	NSMenuItem *viewMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:viewMenuItem];
	NSMenu *viewMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"View", @"View menu title.")];
	NSMenuItem *queryWorkspace = MADAddMenuItem(viewMenu, NSLocalizedString(@"Query Workspace", @"View menu item that shows the query workspace."), @selector(showQueryWorkspace:), @"1", self);
	MADSetMenuSymbol(queryWorkspace, @"tablecells");
	NSMenuItem *designerWorkspace = MADAddMenuItem(viewMenu, NSLocalizedString(@"Designer Workspace", @"View menu item that shows the layout workspace."), @selector(showDesignerWorkspace:), @"2", self);
	MADSetMenuSymbol(designerWorkspace, @"rectangle.3.group");
	NSMenuItem *viewerWorkspace = MADAddMenuItem(viewMenu, NSLocalizedString(@"Viewer Workspace", @"View menu item that shows the report viewer."), @selector(showViewerWorkspace:), @"3", self);
	MADSetMenuSymbol(viewerWorkspace, @"doc.richtext");
	[viewMenu addItem:[NSMenuItem separatorItem]];
	MADAddMenuItem(viewMenu, NSLocalizedString(@"Zoom In", @"View menu item that zooms in."), @selector(viewerZoomIn:), @"+", nil);
	MADAddMenuItem(viewMenu, NSLocalizedString(@"Zoom Out", @"View menu item that zooms out."), @selector(viewerZoomOut:), @"-", nil);
	MADAddMenuItem(viewMenu, NSLocalizedString(@"Actual Size", @"View menu item that resets zoom to 100%."), @selector(viewerZoomActualSize:), @"0", nil);
	[viewMenu addItem:[NSMenuItem separatorItem]];
	MADAddMenuItem(viewMenu, NSLocalizedString(@"Show Left Sidebar", @"View menu item that toggles the designer's left sidebar."), @selector(toggleDesignerLeftSidebar:), @"", nil);
	MADAddMenuItem(viewMenu, NSLocalizedString(@"Show Inspector", @"View menu item that toggles the designer's inspector."), @selector(toggleDesignerInspector:), @"", nil);
	MADAddMenuItem(viewMenu, NSLocalizedString(@"Show Minimap", @"View menu item that toggles the designer's minimap."), @selector(toggleDesignerMinimap:), @"", nil);
	MADAddMenuItem(viewMenu, NSLocalizedString(@"Show Database Tables", @"View menu item that toggles the query schema sidebar."), @selector(toggleQuerySchemaSidebar:), @"", nil);
	MADAddMenuItem(viewMenu, NSLocalizedString(@"Show Grid", @"View menu item that toggles the designer's grid."), @selector(toggleDesignerGrid:), @"", nil);
	MADAddMenuItem(viewMenu, NSLocalizedString(@"Snap to Grid", @"View menu item that toggles snapping to the grid."), @selector(toggleDesignerSnap:), @"", nil);
	MADAddMenuItem(viewMenu, NSLocalizedString(@"Show Rulers", @"View menu item that toggles the designer's rulers."), @selector(toggleDesignerRulers:), @"", nil);
	[viewMenu addItem:[NSMenuItem separatorItem]];
	NSMenuItem *fullScreen = MADAddMenuItem(viewMenu, NSLocalizedString(@"Enter Full Screen", @"View menu item that enters full screen."), @selector(toggleFullScreen:), @"f", nil);
	fullScreen.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagControl;
	[viewMenuItem setSubmenu:viewMenu];

	// Window Menu
	NSMenuItem *windowMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:windowMenuItem];
	NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Window", @"Window menu title.")];
	MADAddMenuItem(windowMenu, NSLocalizedString(@"Minimize", @"Window menu item that minimizes the window."), @selector(performMiniaturize:), @"m", nil);
	MADAddMenuItem(windowMenu, NSLocalizedString(@"Zoom", @"Window menu item that zooms the window."), @selector(performZoom:), @"", nil);
	[windowMenu addItem:[NSMenuItem separatorItem]];
	MADAddMenuItem(windowMenu, NSLocalizedString(@"Bring All to Front", @"Window menu item that brings all windows to the front."), @selector(arrangeInFront:), @"", nil);
	[windowMenuItem setSubmenu:windowMenu];
	[NSApp setWindowsMenu:windowMenu];

	// Help Menu
	NSMenuItem *helpMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:helpMenuItem];
	NSMenu *helpMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Help", @"Help menu title.")];
	NSMenuItem *overviewHelpItem = MADAddMenuItem(helpMenu, NSLocalizedString(@"MAD Designer Overview", @"Help menu item that shows the About overview. MAD Designer is a brand."), @selector(showAboutOverview:), @"", self);
	MADSetMenuSymbol(overviewHelpItem, @"questionmark.circle");
	MADAddMenuItem(helpMenu, NSLocalizedString(@"Licensing & Relink Notice", @"Help menu item that shows the licence and relink notice."), @selector(showAboutLicensing:), @"", self);
	MADAddMenuItem(helpMenu, NSLocalizedString(@"Third-Party Acknowledgements", @"Help menu item that lists third-party components."), @selector(showAboutAcknowledgements:), @"", self);
	[helpMenu addItem:[NSMenuItem separatorItem]];
	MADAddMenuItem(helpMenu, NSLocalizedString(@"Show Tips Again", @"Help menu item that restores the dismissed first-run tips."), @selector(showTipsAgain:), @"", self);
	[helpMenuItem setSubmenu:helpMenu];
	[NSApp setHelpMenu:helpMenu];
}

#pragma mark - Open Recent

- (void)rebuildOpenRecentMenu {
	NSMenu *menu = self.openRecentMenu;
	if (menu == nil) return;
	[menu removeAllItems];
	NSArray<NSURL *> *urls = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
	NSUInteger count = MIN(urls.count, 10);
	for (NSUInteger i = 0; i < count; i++) {
		NSURL *url = urls[i];
		NSString *title = url.lastPathComponent.length > 0 ? url.lastPathComponent : url.path;
		NSMenuItem *item = MADAddMenuItem(menu, title, @selector(openRecentDocument:), @"", self);
		item.representedObject = url;
		item.toolTip = url.path;
	}
	if (count == 0) {
		NSMenuItem *empty = MADAddMenuItem(menu, NSLocalizedString(@"No Recent Reports", @"Open Recent submenu placeholder when there are no recent reports."), NULL, @"", nil);
		empty.enabled = NO;
		return;
	}
	[menu addItem:[NSMenuItem separatorItem]];
	MADAddMenuItem(menu, NSLocalizedString(@"Clear Menu", @"Open Recent submenu item that clears the recent-report list."), @selector(clearRecentMenu:), @"", self);
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
	if (menu == self.openRecentMenu || [menu.title isEqualToString:NSLocalizedString(@"File", @"File menu title.")]) {
		[self rebuildOpenRecentMenu];
	}
}

- (void)openRecentDocument:(NSMenuItem *)sender {
	NSURL *url = sender.representedObject;
	if (![url isKindOfClass:[NSURL class]]) return;
	[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url
																		  display:YES
																completionHandler:^(NSDocument * __unused document, BOOL __unused documentWasAlreadyOpen, NSError *error) {
		if (error != nil) {
			[NSApp presentError:error];
		}
	}];
}

- (void)clearRecentMenu:(nullable id) __unused sender {
	[[NSDocumentController sharedDocumentController] clearRecentDocuments:nil];
	[self rebuildOpenRecentMenu];
}

- (void)showTipsAgain:(nullable id) __unused sender {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	for (NSString *key in @[@"MADMacTip.query", @"MADMacTip.designer", @"MADMacTip.viewer"]) {
		[defaults removeObjectForKey:key];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:MADMacTipBarDidResetNotification object:nil];
}

#pragma mark - Actions

- (MADMacAboutWindowController *)aboutWindowController {
	if (_aboutWindowController == nil) {
		_aboutWindowController = [[MADMacAboutWindowController alloc] init];
	}
	return _aboutWindowController;
}

- (void)showAboutWindow:(nullable id)sender {
	[self.aboutWindowController showWindow:sender];
	[self.aboutWindowController.window makeKeyAndOrderFront:sender];
}

- (void)showAboutOverview:(nullable id)sender {
	[self.aboutWindowController switchToTab:MADMacAboutTabOverview];
	[self showAboutWindow:sender];
}

- (void)showAboutLicensing:(nullable id)sender {
	[self.aboutWindowController switchToTab:MADMacAboutTabLicensing];
	[self showAboutWindow:sender];
}

- (void)showAboutAcknowledgements:(nullable id)sender {
	[self.aboutWindowController switchToTab:MADMacAboutTabAcknowledgements];
	[self showAboutWindow:sender];
}

- (void)newDocumentFromDatabase:(nullable id) __unused sender {
	MADMacDocumentController *docController = (MADMacDocumentController *)[NSDocumentController sharedDocumentController];
	if ([docController respondsToSelector:@selector(dismissOpenPanelIfNeeded)]) {
		[docController dismissOpenPanelIfNeeded];
	}
	_connectionWindowController = [[MADMacConnectionWindowController alloc] init];
	__weak typeof(self) weakSelf = self;
	__weak MADMacConnectionWindowController *weakConnWC = _connectionWindowController;
	_connectionWindowController.onDocumentCreated = ^(MADHeadlessDocument *headlessDoc, NSURL *savedURL) {
		MADMacDocument *doc = [[MADMacDocument alloc] init];
		doc.fileURL = savedURL;
		doc.sessionCredentials = weakConnWC.lastCredentials;
		[doc adoptHeadlessDocument:headlessDoc];
		[[NSDocumentController sharedDocumentController] addDocument:doc];
		[doc makeWindowControllers];
		[doc showWindows];
		MADMacWindowController *wc = doc.windowControllers.firstObject;
		[wc switchToWorkspaceTab:MADMacWorkspaceTabQuery];
		weakSelf.connectionWindowController = nil;
	};
	[_connectionWindowController showWindow:self];
}

- (void)newDocumentWithChooser:(nullable id)sender {
	NSAlert *alert = [[NSAlert alloc] init];
	alert.messageText = NSLocalizedString(@"New Report", @"New report chooser title.");
	alert.informativeText = NSLocalizedString(@"Choose the type of report to create.", @"New report chooser prompt.");
	[alert addButtonWithTitle:NSLocalizedString(@"Standard Report", @"New report chooser: the standard report option.")];
	[alert addButtonWithTitle:NSLocalizedString(@"Composition Report", @"New report chooser: the composition option.")];
	[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button.")];
	NSModalResponse response = [alert runModal];
	if (response == NSAlertFirstButtonReturn) {
		[self newDocumentFromDatabase:sender];
	} else if (response == NSAlertSecondButtonReturn) {
		[self newCompositionDocument:sender];
	}
}

- (void)newCompositionDocument:(nullable id) __unused sender {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	panel.title = NSLocalizedString(@"Choose Reports to Compose", @"Composition child picker title.");
	panel.prompt = NSLocalizedString(@"Choose", @"Composition child picker confirm button.");
	panel.allowsMultipleSelection = YES;
	panel.canChooseDirectories = NO;
	panel.canChooseFiles = YES;
	panel.allowedContentTypes = [MADMacDocumentController allowedMadContentTypes];
	if ([panel runModal] != NSModalResponseOK) return;
	NSArray<NSURL *> *childURLs = panel.URLs;
	if (childURLs.count == 0) return;

	NSSavePanel *savePanel = [NSSavePanel savePanel];
	savePanel.title = NSLocalizedString(@"Save Composition", @"Composition destination title.");
	savePanel.prompt = NSLocalizedString(@"Create", @"Composition destination confirm button.");
	savePanel.allowedContentTypes = [MADMacDocumentController allowedMadContentTypes];
	savePanel.nameFieldStringValue = NSLocalizedString(@"Composition.mad", @"Default composition file name.");
	if ([savePanel runModal] != NSModalResponseOK) return;

	[self createCompositionDocumentAtURL:savePanel.URL withChildURLs:childURLs];
}

- (void)createCompositionDocumentAtURL:(NSURL *)destinationURL
						  withChildURLs:(NSArray<NSURL *> *)childURLs {
	NSError *error = nil;
	MADHeadlessDocument *empty = [MADHeadlessDocument createEmptyDocumentAtURL:destinationURL error:&error];
	if (empty == nil) {
		[NSApp presentError:error];
		return;
	}
	MADMacDocument *document = [[MADMacDocument alloc] init];
	document.fileURL = destinationURL;
	[document adoptHeadlessDocument:empty];

	if ([document addRootQueryNamed:NSLocalizedString(@"root", @"Default composed root name.") error:&error] == nil) {
		[NSApp presentError:error];
		return;
	}
	for (NSURL *childURL in childURLs) {
		NSString *name = childURL.lastPathComponent.stringByDeletingPathExtension;
		RptqQuery *child = [document importChildFromURL:childURL name:name error:&error];
		if (child == nil || [document addChildQuery:child error:&error] == nil) {
			[NSApp presentError:error];
			return;
		}
	}

	[[NSDocumentController sharedDocumentController] addDocument:document];
	[document makeWindowControllers];
	[document showWindows];
	MADMacWindowController *windowController = (MADMacWindowController *)document.windowControllers.firstObject;
	[windowController switchToWorkspaceTab:MADMacWorkspaceTabQuery];
}

- (void)convertCurrentDocumentToComposition:(nullable id) __unused sender {
	MADMacDocument *document = [self activeMacDocument];
	if (document == nil || document.isComposed) return;
	NSError *error = nil;
	if ([document convertToCompositionWithChildName:nil error:&error] == nil) {
		[NSApp presentError:error];
		return;
	}
	[[self activeWindowController] switchToWorkspaceTab:MADMacWorkspaceTabQuery];
}

- (nullable MADMacDocument *)activeMacDocument {
	return [self activeWindowController].madDocument;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	SEL action = menuItem.action;
	if (action == @selector(convertCurrentDocumentToComposition:)) {
		MADMacDocument *document = [self activeMacDocument];
		return document != nil && !document.isComposed;
	}
	if (action == @selector(openRecentDocument:)) {
		id object = menuItem.representedObject;
		if (![object isKindOfClass:[NSURL class]]) return NO;
		NSString *path = ((NSURL *)object).path;
		return path.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:path];
	}
	if (action == @selector(showQueryWorkspace:) ||
		action == @selector(showDesignerWorkspace:) ||
		action == @selector(showViewerWorkspace:) ||
		action == @selector(refreshCurrentReport:) ||
		action == @selector(exportCurrentReport:) ||
		action == @selector(printCurrentReport:) ||
		action == @selector(editCurrentDatabaseConnection:)) {
		return [self activeWindowController] != nil;
	}
	return YES;
}

- (nullable MADMacWindowController *)activeWindowController {
	NSWindowController *wc = [NSApp mainWindow].windowController;
	if ([wc isKindOfClass:[MADMacWindowController class]]) {
		return (MADMacWindowController *)wc;
	}
	return nil;
}

- (void)showQueryWorkspace:(nullable id) __unused sender {
	[[self activeWindowController] switchToWorkspaceTab:MADMacWorkspaceTabQuery];
}

- (void)showDesignerWorkspace:(nullable id) __unused sender {
	[[self activeWindowController] switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
}

- (void)showViewerWorkspace:(nullable id) __unused sender {
	[[self activeWindowController] switchToWorkspaceTab:MADMacWorkspaceTabViewer];
}

- (void)refreshCurrentReport:(nullable id)sender {
	[[self activeWindowController] refreshReportAction:sender];
}

- (void)exportCurrentReport:(nullable id)sender {
	[[self activeWindowController] exportReportAction:sender];
}

- (void)printCurrentReport:(nullable id)sender {
	[[self activeWindowController] printReportAction:sender];
}

- (void)editCurrentDatabaseConnection:(nullable id)sender {
	[[self activeWindowController] editDatabaseConnectionAction:sender];
}

@end
