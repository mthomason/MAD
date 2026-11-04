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
#import "MADStoreLegacyConverter.h"

#import <MAD/MAD.h>
#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADURLFactory.h>
#import <MADAPI/MADDatabaseDriverRegistry.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <MADMySQL/MADDatabaseConnectionMySql.h>
#import <MADTdsClient/MADDatabaseConnectionSQLServer.h>
#import <MADPostgres/MADDatabaseConnectionPostgres.h>

@interface MADMacAppDelegate ()

@property (nonatomic, strong, nullable) MADMacConnectionWindowController *connectionWindowController;
@property (nonatomic, strong, readwrite) MADMacAboutWindowController *aboutWindowController;

@end

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
	NSMenuItem *aboutItem = [appMenu addItemWithTitle:NSLocalizedString(@"About MAD Designer", @"Application menu item that opens the About window. MAD Designer is a brand.")
												action:@selector(showAboutWindow:)
										 keyEquivalent:@""];
	aboutItem.target = self;
	[appMenu addItem:[NSMenuItem separatorItem]];
	[appMenu addItemWithTitle:NSLocalizedString(@"Hide MAD Designer", @"Application menu item that hides the app. MAD Designer is a brand.")
						action:@selector(hide:)
				 keyEquivalent:@"h"];
	[appMenu addItemWithTitle:NSLocalizedString(@"Quit MAD Designer", @"Application menu item that quits the app. MAD Designer is a brand.")
						action:@selector(terminate:)
				 keyEquivalent:@"q"];
	[appMenuItem setSubmenu:appMenu];

	// File Menu
	NSMenuItem *fileMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:fileMenuItem];
	NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"File", @"File menu title.")];
	[fileMenu addItemWithTitle:NSLocalizedString(@"New Document…", @"File menu item that starts a new report.")
						action:@selector(newDocument:)
				 keyEquivalent:@"n"];
	[fileMenu addItemWithTitle:NSLocalizedString(@"Open…", @"File menu item that opens an existing report.")
						action:@selector(openDocument:)
				 keyEquivalent:@"o"];
	[fileMenu addItem:[NSMenuItem separatorItem]];
	[fileMenu addItemWithTitle:NSLocalizedString(@"Close", @"File menu item that closes the window.")
						action:@selector(performClose:)
				 keyEquivalent:@"w"];
	[fileMenu addItemWithTitle:NSLocalizedString(@"Save", @"File menu item that saves the report.")
						action:@selector(saveDocument:)
				 keyEquivalent:@"s"];
	[fileMenu addItemWithTitle:NSLocalizedString(@"Save As…", @"File menu item that saves the report under a new name.")
						action:@selector(saveDocumentAs:)
				 keyEquivalent:@"S"];
	[fileMenu addItem:[NSMenuItem separatorItem]];
	[fileMenu addItemWithTitle:NSLocalizedString(@"Database Connection…", @"Menu item that edits the database connection settings.")
						action:@selector(editCurrentDatabaseConnection:)
				 keyEquivalent:@""];
	[fileMenu addItem:[NSMenuItem separatorItem]];
	[fileMenu addItemWithTitle:NSLocalizedString(@"Export Report…", @"File menu item that exports the rendered report.")
						action:@selector(exportCurrentReport:)
				 keyEquivalent:@"e"];
	[fileMenu addItemWithTitle:NSLocalizedString(@"Print…", @"File menu item that prints the rendered report.")
						action:@selector(printCurrentReport:)
				 keyEquivalent:@"p"];
	[fileMenuItem setSubmenu:fileMenu];

	// Edit Menu
	NSMenuItem *editMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:editMenuItem];
	NSMenu *editMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Edit", @"Edit menu title.")];
	[editMenu addItemWithTitle:NSLocalizedString(@"Undo", @"Edit menu item that undoes the last change.")
						action:@selector(undo:)
				 keyEquivalent:@"z"];	// Undeclared selector 'undo:'
	[editMenu addItemWithTitle:NSLocalizedString(@"Redo", @"Edit menu item that redoes the last undone change.")
						action:@selector(redo:)
				 keyEquivalent:@"Z"];	// Undeclared selector 'redo:'
	[editMenu addItem:[NSMenuItem separatorItem]];
	[editMenu addItemWithTitle:NSLocalizedString(@"Cut", @"Edit menu item that cuts the selection.")
						action:@selector(cut:)
				 keyEquivalent:@"x"];
	[editMenu addItemWithTitle:NSLocalizedString(@"Copy", @"Edit menu item that copies the selection.")
						action:@selector(copy:)
				 keyEquivalent:@"c"];
	[editMenu addItemWithTitle:NSLocalizedString(@"Paste", @"Edit menu item that pastes the clipboard.")
						action:@selector(paste:)
				 keyEquivalent:@"v"];
	[editMenu addItemWithTitle:NSLocalizedString(@"Delete", @"Edit menu item that deletes the selection.")
						action:@selector(delete:)
				 keyEquivalent:@""];
	[editMenu addItemWithTitle:NSLocalizedString(@"Select All", @"Edit menu item that selects everything.")
						action:@selector(selectAll:)
				 keyEquivalent:@"a"];
	[editMenuItem setSubmenu:editMenu];

	// View Menu
	NSMenuItem *viewMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:viewMenuItem];
	NSMenu *viewMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"View", @"View menu title.")];
	[viewMenu addItemWithTitle:NSLocalizedString(@"MAD Query Workspace", @"View menu item that shows the query workspace. MAD Query is a brand.")
						action:@selector(showQueryWorkspace:)
				 keyEquivalent:@"1"];
	[viewMenu addItemWithTitle:NSLocalizedString(@"MAD Designer Workspace", @"View menu item that shows the layout workspace. MAD Designer is a brand.")
						action:@selector(showDesignerWorkspace:)
				 keyEquivalent:@"2"];
	[viewMenu addItemWithTitle:NSLocalizedString(@"MAD Viewer Workspace", @"View menu item that shows the report viewer. MAD Viewer is a brand.")
						action:@selector(showViewerWorkspace:)
				 keyEquivalent:@"3"];
	[viewMenuItem setSubmenu:viewMenu];

	// Report Menu
	NSMenuItem *reportMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:reportMenuItem];
	NSMenu *reportMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Report", @"Report menu title.")];
	[reportMenu addItemWithTitle:NSLocalizedString(@"Refresh Report Data", @"Report menu item that re-runs the query and re-renders the report.")
						  action:@selector(refreshCurrentReport:)
				   keyEquivalent:@"r"];
	[reportMenu addItem:[NSMenuItem separatorItem]];
	[reportMenu addItemWithTitle:NSLocalizedString(@"Database Connection…", @"Menu item that edits the database connection settings.")
						  action:@selector(editCurrentDatabaseConnection:)
				   keyEquivalent:@""];
	[reportMenuItem setSubmenu:reportMenu];

	// Window Menu
	NSMenuItem *windowMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:windowMenuItem];
	NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Window", @"Window menu title.")];
	[windowMenu addItemWithTitle:NSLocalizedString(@"Minimize", @"Window menu item that minimizes the window.")
						  action:@selector(performMiniaturize:)
				   keyEquivalent:@"m"];
	[windowMenu addItemWithTitle:NSLocalizedString(@"Zoom", @"Window menu item that zooms the window.")
						  action:@selector(performZoom:)
				   keyEquivalent:@""];
	[windowMenuItem setSubmenu:windowMenu];
	[NSApp setWindowsMenu:windowMenu];

	// Help Menu
	NSMenuItem *helpMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:helpMenuItem];
	NSMenu *helpMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Help", @"Help menu title.")];
	NSMenuItem *overviewHelpItem = [helpMenu addItemWithTitle:NSLocalizedString(@"MAD Designer Overview", @"Help menu item that shows the About overview. MAD Designer is a brand.")
													   action:@selector(showAboutOverview:)
												keyEquivalent:@""];
	overviewHelpItem.target = self;
	NSMenuItem *licensingHelpItem = [helpMenu addItemWithTitle:NSLocalizedString(@"Licensing & Relink Notice", @"Help menu item that shows the licence and relink notice.")
														 action:@selector(showAboutLicensing:)
												  keyEquivalent:@""];
	licensingHelpItem.target = self;
	NSMenuItem *ackHelpItem = [helpMenu addItemWithTitle:NSLocalizedString(@"Third-Party Acknowledgements", @"Help menu item that lists third-party components.")
												   action:@selector(showAboutAcknowledgements:)
											keyEquivalent:@""];
	ackHelpItem.target = self;
	[helpMenuItem setSubmenu:helpMenu];
	[NSApp setHelpMenu:helpMenu];
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
