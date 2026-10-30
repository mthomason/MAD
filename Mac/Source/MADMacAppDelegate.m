//
//  MADMacAppDelegate.m
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMacAppDelegate.h"
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
	NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"MAD Designer"];
	[appMenu addItemWithTitle:@"About MAD Designer" action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
	[appMenu addItem:[NSMenuItem separatorItem]];
	[appMenu addItemWithTitle:@"Hide MAD Designer" action:@selector(hide:) keyEquivalent:@"h"];
	[appMenu addItemWithTitle:@"Quit MAD Designer" action:@selector(terminate:) keyEquivalent:@"q"];
	[appMenuItem setSubmenu:appMenu];

	// File Menu
	NSMenuItem *fileMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:fileMenuItem];
	NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
	[fileMenu addItemWithTitle:@"New Document…" action:@selector(newDocument:) keyEquivalent:@"n"];
	[fileMenu addItemWithTitle:@"Open…" action:@selector(openDocument:) keyEquivalent:@"o"];
	[fileMenu addItem:[NSMenuItem separatorItem]];
	[fileMenu addItemWithTitle:@"Close" action:@selector(performClose:) keyEquivalent:@"w"];
	[fileMenu addItemWithTitle:@"Save" action:@selector(saveDocument:) keyEquivalent:@"s"];
	[fileMenu addItemWithTitle:@"Save As…" action:@selector(saveDocumentAs:) keyEquivalent:@"S"];
	[fileMenu addItem:[NSMenuItem separatorItem]];
	[fileMenu addItemWithTitle:@"Export Report…" action:@selector(exportCurrentReport:) keyEquivalent:@"e"];
	[fileMenu addItemWithTitle:@"Print…" action:@selector(printCurrentReport:) keyEquivalent:@"p"];
	[fileMenuItem setSubmenu:fileMenu];

	// Edit Menu
	NSMenuItem *editMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:editMenuItem];
	NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
	[editMenu addItemWithTitle:@"Undo" action:@selector(undo:) keyEquivalent:@"z"];
	[editMenu addItemWithTitle:@"Redo" action:@selector(redo:) keyEquivalent:@"Z"];
	[editMenu addItem:[NSMenuItem separatorItem]];
	[editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
	[editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
	[editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
	[editMenu addItemWithTitle:@"Delete" action:@selector(delete:) keyEquivalent:@""];
	[editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];
	[editMenuItem setSubmenu:editMenu];

	// View Menu
	NSMenuItem *viewMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:viewMenuItem];
	NSMenu *viewMenu = [[NSMenu alloc] initWithTitle:@"View"];
	[viewMenu addItemWithTitle:@"MAD Query Workspace" action:@selector(showQueryWorkspace:) keyEquivalent:@"1"];
	[viewMenu addItemWithTitle:@"MAD Designer Workspace" action:@selector(showDesignerWorkspace:) keyEquivalent:@"2"];
	[viewMenu addItemWithTitle:@"MAD Viewer Workspace" action:@selector(showViewerWorkspace:) keyEquivalent:@"3"];
	[viewMenuItem setSubmenu:viewMenu];

	// Report Menu
	NSMenuItem *reportMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:reportMenuItem];
	NSMenu *reportMenu = [[NSMenu alloc] initWithTitle:@"Report"];
	[reportMenu addItemWithTitle:@"Refresh Report Data" action:@selector(refreshCurrentReport:) keyEquivalent:@"r"];
	[reportMenuItem setSubmenu:reportMenu];

	// Window Menu
	NSMenuItem *windowMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:windowMenuItem];
	NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
	[windowMenu addItemWithTitle:@"Minimize" action:@selector(performMiniaturize:) keyEquivalent:@"m"];
	[windowMenu addItemWithTitle:@"Zoom" action:@selector(performZoom:) keyEquivalent:@""];
	[windowMenuItem setSubmenu:windowMenu];
	[NSApp setWindowsMenu:windowMenu];
}

#pragma mark - Actions

- (void)newDocumentFromDatabase:(nullable id) __unused sender {
	MADMacDocumentController *docController = (MADMacDocumentController *)[NSDocumentController sharedDocumentController];
	if ([docController respondsToSelector:@selector(dismissOpenPanelIfNeeded)]) {
		[docController dismissOpenPanelIfNeeded];
	}
	_connectionWindowController = [[MADMacConnectionWindowController alloc] init];
	__weak typeof(self) weakSelf = self;
	_connectionWindowController.onDocumentCreated = ^(MADHeadlessDocument *headlessDoc, NSURL *savedURL) {
		MADMacDocument *doc = [[MADMacDocument alloc] init];
		doc.fileURL = savedURL;
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

@end
