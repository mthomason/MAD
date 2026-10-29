//
//  MADMacAppDelegate.m
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMacAppDelegate.h"
#import "MADMacConnectionWindowController.h"
#import "MADMacDocument.h"
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

@property (nonatomic, strong, nullable) NSWindow *welcomeWindow;
@property (nonatomic, strong, nullable) MADMacConnectionWindowController *connectionWindowController;

@end

@implementation MADMacAppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *) __unused notification {
	// Ensure driver, exporter, and legacy store converter classes are linked and registered.
	[MADLegacyStoreConversion setConverter:[[MADStoreLegacyConverter alloc] init]];
	(void)[MADDatabaseConnectionSqlite3 class];
	(void)[MADDatabaseConnectionMySql class];
	(void)[MADDatabaseConnectionSQLServer class];
	(void)[MADDatabaseConnectionPostgres class];

	[self installBundledChinookSampleIfNeeded];
	[self buildMainMenu];
}

- (void)applicationDidFinishLaunching:(NSNotification *) __unused notification {
	[NSApp activateIgnoringOtherApps:YES];
	if ([NSDocumentController sharedDocumentController].documents.count == 0) {
		[self showWelcomeWindow:nil];
	}
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *) __unused sender {
	return NO;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *) __unused sender hasVisibleWindows:(BOOL)flag {
	if (!flag) {
		[self showWelcomeWindow:nil];
	}
	return YES;
}

- (void)installBundledChinookSampleIfNeeded {
	NSString *bundled = [[NSBundle mainBundle] pathForResource:@"chinook" ofType:@"sqlite3"];
	if (bundled.length == 0 || ![[NSFileManager defaultManager] fileExistsAtPath:bundled]) {
		return;
	}
	NSURL *supportDir = [MADURLFactory newURLLocalApplicationSupportDirectoryForGroupID:[MADApplication groupIdentifier]];
	[[NSFileManager defaultManager] createDirectoryAtURL:supportDir withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *dest = [supportDir URLByAppendingPathComponent:@"chinook.sqlite3"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:dest.path]) {
		[[NSFileManager defaultManager] copyItemAtURL:[NSURL fileURLWithPath:bundled] toURL:dest error:NULL];
	}
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
	[appMenu addItemWithTitle:@"Welcome Window" action:@selector(showWelcomeWindow:) keyEquivalent:@"0"];
	[appMenu addItem:[NSMenuItem separatorItem]];
	[appMenu addItemWithTitle:@"Hide MAD Designer" action:@selector(hide:) keyEquivalent:@"h"];
	[appMenu addItemWithTitle:@"Quit MAD Designer" action:@selector(terminate:) keyEquivalent:@"q"];
	[appMenuItem setSubmenu:appMenu];

	// File Menu
	NSMenuItem *fileMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:fileMenuItem];
	NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
	[fileMenu addItemWithTitle:@"New From Database Connection…" action:@selector(newDocumentFromDatabase:) keyEquivalent:@"n"];
	[fileMenu addItemWithTitle:@"Open…" action:@selector(openDocument:) keyEquivalent:@"o"];

	NSMenuItem *samplesItem = [[NSMenuItem alloc] initWithTitle:@"Open Sample Report" action:NULL keyEquivalent:@""];
	NSMenu *samplesMenu = [[NSMenu alloc] initWithTitle:@"Open Sample Report"];
	[samplesMenu addItemWithTitle:@"London Report (Chinook SQLite)" action:@selector(openLondonSample:) keyEquivalent:@""];
	[samplesMenu addItemWithTitle:@"Music Catalog Report (Chinook SQLite)" action:@selector(openMusicSample:) keyEquivalent:@""];
	samplesItem.submenu = samplesMenu;
	[fileMenu addItem:samplesItem];

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

#pragma mark - Welcome Window

- (void)showWelcomeWindow:(nullable id) __unused sender {
	if (_welcomeWindow == nil) {
		NSRect frame = NSMakeRect(0, 0, 520, 320);
		NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable;
		_welcomeWindow = [[NSWindow alloc] initWithContentRect:frame
													 styleMask:style
													   backing:NSBackingStoreBuffered
														 defer:NO];
		_welcomeWindow.title = @"Welcome to MAD Designer for macOS";
		_welcomeWindow.releasedWhenClosed = NO;
		[_welcomeWindow center];

		NSView *content = _welcomeWindow.contentView;

		NSTextField *title = [NSTextField labelWithString:@"MAD Designer"];
		title.font = [NSFont boldSystemFontOfSize:24.0];
		title.frame = NSMakeRect(32, 256, 456, 34);
		[content addSubview:title];

		NSTextField *subtitle = [NSTextField labelWithString:@"Mobile Analytics Document Designer & Business Intelligence Engine\nSQLite 3 • MySQL / MariaDB • SQL Server • PostgreSQL"];
		subtitle.font = [NSFont systemFontOfSize:13.0];
		subtitle.textColor = [NSColor secondaryLabelColor];
		subtitle.frame = NSMakeRect(32, 208, 456, 40);
		[content addSubview:subtitle];

		NSButton *newBtn = [NSButton buttonWithTitle:@"New Report from Database Connection…"
											  target:self
											  action:@selector(newDocumentFromDatabase:)];
		newBtn.frame = NSMakeRect(32, 152, 456, 32);
		[content addSubview:newBtn];

		NSButton *openBtn = [NSButton buttonWithTitle:@"Open Existing .mad Report…"
											   target:self
											   action:@selector(openExistingDocumentFromWelcome:)];
		openBtn.frame = NSMakeRect(32, 112, 456, 32);
		[content addSubview:openBtn];

		NSButton *londonBtn = [NSButton buttonWithTitle:@"Open Sample Report: London.mad (Chinook SQLite)"
												 target:self
												 action:@selector(openLondonSample:)];
		londonBtn.frame = NSMakeRect(32, 64, 456, 32);
		[content addSubview:londonBtn];

		NSButton *musicBtn = [NSButton buttonWithTitle:@"Open Sample Report: Music.mad (Chinook SQLite)"
												target:self
												action:@selector(openMusicSample:)];
		musicBtn.frame = NSMakeRect(32, 24, 456, 32);
		[content addSubview:musicBtn];
	}
	[_welcomeWindow makeKeyAndOrderFront:nil];
}

#pragma mark - Actions

- (void)openExistingDocumentFromWelcome:(nullable id)sender {
	[_welcomeWindow orderOut:nil];
	[[NSDocumentController sharedDocumentController] openDocument:sender];
}

- (void)newDocumentFromDatabase:(nullable id) __unused sender {
	[_welcomeWindow orderOut:nil];
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

- (void)openBundledSampleNamed:(NSString *)sampleName {
	[_welcomeWindow orderOut:nil];
	[self installBundledChinookSampleIfNeeded];

	NSString *samplePath = [[NSBundle mainBundle] pathForResource:sampleName ofType:@"mad"];
	if (samplePath.length == 0 || ![[NSFileManager defaultManager] fileExistsAtPath:samplePath]) {
		return;
	}

	NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
						 [NSString stringWithFormat:@"%@.mad", sampleName]];
	NSURL *workingURL = [NSURL fileURLWithPath:tmpPath];
	[[NSFileManager defaultManager] removeItemAtURL:workingURL error:NULL];
	[[NSFileManager defaultManager] copyItemAtURL:[NSURL fileURLWithPath:samplePath] toURL:workingURL error:NULL];

	[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:workingURL
																		   display:YES
																 completionHandler:^(NSDocument * _Nullable __unused document, BOOL __unused documentWasAlreadyOpen, NSError * _Nullable __unused error) {
	}];
}

- (void)openLondonSample:(nullable id) __unused sender {
	[self openBundledSampleNamed:@"London"];
}

- (void)openMusicSample:(nullable id) __unused sender {
	[self openBundledSampleNamed:@"Music"];
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
