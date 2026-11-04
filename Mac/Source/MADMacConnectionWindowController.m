//
//  MADMacConnectionWindowController.m
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMacConnectionWindowController.h"
#import "MADMacDocument.h"

#import <MAD/MAD.h>
#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADKeyChain.h>
#import <MADFoundation/MADURLFactory.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADConnectionsPropertiesProtocol.h>
#import <MADAPI/MADDatabaseConnectionsPropertiesURLProtocol.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <MADMySQL/MADDatabaseConnectionMySql.h>
#import <MADTdsClient/MADDatabaseConnectionSQLServer.h>
#import <MADPostgres/MADDatabaseConnectionPostgres.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

typedef NS_ENUM(NSInteger, MADMacDatabaseKind) {
	MADMacDatabaseKindSQLite3 = 0,
	MADMacDatabaseKindMySQL = 1,
	MADMacDatabaseKindSQLServer = 2,
	MADMacDatabaseKindPostgreSQL = 3,
};

@interface MADMacFlippedView : NSView
@end

@implementation MADMacFlippedView
- (BOOL)isFlipped {
	return YES;
}
@end

@interface MADMacConnectionWindowController ()

@property (nonatomic, weak, readwrite, nullable) MADMacDocument *editingDocument;
@property (nonatomic, strong, readwrite, nullable) MADCredential *lastCredentials;
@property (nonatomic, copy, nullable) NSString *initialStatusPrompt;

@property (nonatomic, strong) NSImageView *headerIconView;
@property (nonatomic, strong) NSTextField *headerTitleLabel;
@property (nonatomic, strong) NSTextField *headerSubtitleLabel;

@property (nonatomic, strong) NSBox *formContainerBox;
@property (nonatomic, strong) MADMacFlippedView *formContentView;

@property (nonatomic, strong) NSTextField *driverLabel;
@property (nonatomic, strong) NSPopUpButton *driverPopup;
@property (nonatomic, strong) NSBox *driverDivider;

@property (nonatomic, strong) NSTextField *sqliteLabel;
@property (nonatomic, strong) NSTextField *sqlitePathField;
@property (nonatomic, strong) NSButton *browseSQLiteButton;
@property (nonatomic, strong) NSTextField *sqliteHintLabel;

@property (nonatomic, strong) NSTextField *hostLabel;
@property (nonatomic, strong) NSTextField *hostField;
@property (nonatomic, strong) NSTextField *portLabel;
@property (nonatomic, strong) NSTextField *portField;

@property (nonatomic, strong) NSTextField *serverInstanceLabel;
@property (nonatomic, strong) NSTextField *serverInstanceField;

@property (nonatomic, strong) NSTextField *databaseLabel;
@property (nonatomic, strong) NSTextField *databaseField;

@property (nonatomic, strong) NSTextField *usernameLabel;
@property (nonatomic, strong) NSTextField *usernameField;

@property (nonatomic, strong) NSTextField *passwordLabel;
@property (nonatomic, strong) NSSecureTextField *passwordField;

@property (nonatomic, strong) NSButton *saveKeychainCheckbox;

@property (nonatomic, strong) NSTextField *statusLabel;
@property (nonatomic, strong) NSProgressIndicator *spinner;
@property (nonatomic, strong) NSButton *cancelButton;
@property (nonatomic, strong) NSButton *testButton;
@property (nonatomic, strong) NSButton *createButton;

@end

@implementation MADMacConnectionWindowController

- (instancetype)init {
	return [self initWithDocument:nil statusPrompt:nil];
}

- (instancetype)initWithDocument:(nullable MADMacDocument *)document
					statusPrompt:(nullable NSString *)statusPrompt {
	NSRect frame = NSMakeRect(0, 0, 540, 280);
	NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable;
	NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
												   styleMask:style
													 backing:NSBackingStoreBuffered
													   defer:NO];
	window.title = (document != nil)
		? NSLocalizedString(@"Database Connection Settings", @"Connection window title when editing an existing report's connection.")
		: NSLocalizedString(@"New Report from Database Connection", @"Connection window title when creating a report.");
	window.releasedWhenClosed = NO;

	if (self = [super initWithWindow:window]) {
		_editingDocument = document;
		_initialStatusPrompt = [statusPrompt copy];
		[self buildInterface];
		if (document != nil) {
			[self populateFromDocument:document];
		}
		[self updateDriverSelectionAnimated:NO];
		[window center];
	}
	return self;
}

- (BOOL)savePasswordInKeychain {
	return _saveKeychainCheckbox != nil && _saveKeychainCheckbox.state == NSControlStateValueOn;
}

- (NSTextField *)makeLabel:(NSString *)text
					 frame:(NSRect)frame
					  bold:(BOOL)bold
				 alignment:(NSTextAlignment)alignment {
	NSTextField *label = [NSTextField labelWithString:text];
	label.frame = frame;
	label.font = bold ? [NSFont boldSystemFontOfSize:13.0] : [NSFont systemFontOfSize:12.5];
	label.alignment = alignment;
	return label;
}

- (void)buildInterface {
	MADMacFlippedView *content = [[MADMacFlippedView alloc] initWithFrame:self.window.contentView.bounds];
	content.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	self.window.contentView = content;

	BOOL isEditMode = (_editingDocument != nil);

	// Header banner
	_headerIconView = [[NSImageView alloc] initWithFrame:NSMakeRect(24, 16, 32, 32)];
	if (@available(macOS 11.0, *)) {
		NSImage *icon = [NSImage imageWithSystemSymbolName:@"cylinder.split.1x2"
								  accessibilityDescription:NSLocalizedString(@"Database Connection", @"Accessibility description for the connection window icon.")];
		NSImageSymbolConfiguration *cfg = [NSImageSymbolConfiguration configurationWithPointSize:24.0
																						  weight:NSFontWeightMedium];
		_headerIconView.image = [icon imageWithSymbolConfiguration:cfg] ?: icon;
		_headerIconView.contentTintColor = [NSColor controlAccentColor];
	}
	[content addSubview:_headerIconView];

	NSString *headerTitle = isEditMode
		? NSLocalizedString(@"Database Connection Settings", @"Connection window title when editing an existing report's connection.")
		: NSLocalizedString(@"Create a New Mobile Analytics Document (.mad)", @"Connection window title when creating a report. Mobile Analytics Document is the file type name.");
	_headerTitleLabel = [self makeLabel:headerTitle
								  frame:NSMakeRect(66, 14, 450, 20)
								   bold:YES
							  alignment:NSTextAlignmentLeft];
	[content addSubview:_headerTitleLabel];

	NSString *headerSubtitle = isEditMode
		? NSLocalizedString(@"Update the data source location or server credentials for this report.", @"Connection window subtitle when editing an existing connection.")
		: NSLocalizedString(@"Choose a database driver and configure the source to import its schema.", @"Connection window subtitle when creating a report.");
	_headerSubtitleLabel = [self makeLabel:headerSubtitle
									 frame:NSMakeRect(66, 34, 450, 18)
									  bold:NO
								 alignment:NSTextAlignmentLeft];
	_headerSubtitleLabel.font = [NSFont systemFontOfSize:11.5];
	_headerSubtitleLabel.textColor = [NSColor secondaryLabelColor];
	[content addSubview:_headerSubtitleLabel];

	// Framed Form Container
	_formContainerBox = [[NSBox alloc] initWithFrame:NSMakeRect(20, 62, 500, 140)];
	_formContainerBox.boxType = NSBoxCustom;
	_formContainerBox.borderWidth = 1.0;
	_formContainerBox.cornerRadius = 8.0;
	_formContainerBox.borderColor = [NSColor separatorColor];
	_formContainerBox.fillColor = [[NSColor controlBackgroundColor] colorWithAlphaComponent:0.5];
	_formContainerBox.contentViewMargins = NSZeroSize;

	_formContentView = [[MADMacFlippedView alloc] initWithFrame:NSMakeRect(0, 0, 500, 140)];
	_formContainerBox.contentView = _formContentView;
	[content addSubview:_formContainerBox];

	// Driver selector row
	_driverLabel = [self makeLabel:NSLocalizedString(@"Database Driver:", @"Connection form label for the driver popup.")
							 frame:NSMakeRect(16, 16, 126, 20)
							  bold:NO
						 alignment:NSTextAlignmentRight];
	[_formContentView addSubview:_driverLabel];

	_driverPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(150, 12, 330, 26) pullsDown:NO];
	[_driverPopup addItemsWithTitles:@[
		NSLocalizedString(@"SQLite", @"Database driver name. A brand; do not translate."),
		NSLocalizedString(@"MySQL", @"Database driver name. A brand; do not translate."),
		NSLocalizedString(@"Microsoft SQL Server", @"Database driver name. A Microsoft brand; do not translate."),
		NSLocalizedString(@"PostgreSQL", @"Database driver name. A brand; do not translate.")
	]];
	_driverPopup.target = self;
	_driverPopup.action = @selector(driverPopupChanged:);
	[_formContentView addSubview:_driverPopup];

	_driverDivider = [[NSBox alloc] initWithFrame:NSMakeRect(16, 48, 468, 1)];
	_driverDivider.boxType = NSBoxSeparator;
	[_formContentView addSubview:_driverDivider];

	// SQLite controls
	_sqliteLabel = [self makeLabel:NSLocalizedString(@"SQLite File:", @"Connection form label for the SQLite file path. SQLite is a brand.")
							 frame:NSMakeRect(16, 64, 126, 20)
							  bold:NO
						 alignment:NSTextAlignmentRight];
	[_formContentView addSubview:_sqliteLabel];

	_sqlitePathField = [[NSTextField alloc] initWithFrame:NSMakeRect(150, 60, 232, 24)];
	_sqlitePathField.placeholderString = NSLocalizedString(@"/path/to/database.sqlite3", @"Example file path placeholder. Technical; do not translate.");
	_sqlitePathField.lineBreakMode = NSLineBreakByTruncatingMiddle;
	[_formContentView addSubview:_sqlitePathField];

	_browseSQLiteButton = [NSButton buttonWithTitle:NSLocalizedString(@"Choose File…", @"Connection form button that opens a file chooser.")
											 target:self
											 action:@selector(browseSQLiteFile:)];
	_browseSQLiteButton.frame = NSMakeRect(388, 58, 96, 28);
	[_formContentView addSubview:_browseSQLiteButton];

	_sqliteHintLabel = [self makeLabel:NSLocalizedString(@"Select an existing .sqlite3 or .db database file on your Mac.", @"Connection form hint under the SQLite file field. Keep the file extensions.")
								 frame:NSMakeRect(150, 88, 330, 16)
								  bold:NO
							 alignment:NSTextAlignmentLeft];
	_sqliteHintLabel.font = [NSFont systemFontOfSize:11.0];
	_sqliteHintLabel.textColor = [NSColor secondaryLabelColor];
	[_formContentView addSubview:_sqliteHintLabel];

	// Server controls
	_hostLabel = [self makeLabel:NSLocalizedString(@"Host / Address:", @"Connection form label for the server host name.")
						   frame:NSMakeRect(16, 64, 126, 20)
							bold:NO
					   alignment:NSTextAlignmentRight];
	[_formContentView addSubview:_hostLabel];

	_hostField = [[NSTextField alloc] initWithFrame:NSMakeRect(150, 60, 212, 24)];
	_hostField.stringValue = @"127.0.0.1";
	_hostField.placeholderString = NSLocalizedString(@"127.0.0.1 or db.example.com", @"Example host placeholder. Technical; do not translate.");
	[_formContentView addSubview:_hostField];

	_portLabel = [self makeLabel:NSLocalizedString(@"Port:", @"Connection form label for the server port number.")
						   frame:NSMakeRect(366, 64, 38, 20)
							bold:NO
					   alignment:NSTextAlignmentRight];
	[_formContentView addSubview:_portLabel];

	_portField = [[NSTextField alloc] initWithFrame:NSMakeRect(410, 60, 70, 24)];
	_portField.stringValue = @"3306";
	[_formContentView addSubview:_portField];

	_serverInstanceLabel = [self makeLabel:NSLocalizedString(@"Server Instance:", @"Connection form label for the SQL Server named instance.")
									 frame:NSMakeRect(16, 98, 126, 20)
									  bold:NO
								 alignment:NSTextAlignmentRight];
	[_formContentView addSubview:_serverInstanceLabel];

	_serverInstanceField = [[NSTextField alloc] initWithFrame:NSMakeRect(150, 94, 330, 24)];
	_serverInstanceField.placeholderString = NSLocalizedString(@"Optional named instance (defaults to Host)", @"Placeholder for the SQL Server named instance field.");
	[_formContentView addSubview:_serverInstanceField];

	_databaseLabel = [self makeLabel:NSLocalizedString(@"Database Name:", @"Connection form label for the database name.")
							   frame:NSMakeRect(16, 132, 126, 20)
								bold:NO
						   alignment:NSTextAlignmentRight];
	[_formContentView addSubview:_databaseLabel];

	_databaseField = [[NSTextField alloc] initWithFrame:NSMakeRect(150, 128, 330, 24)];
	_databaseField.placeholderString = NSLocalizedString(@"e.g. Chinook, Northwind, postgres", @"Example database names. The names are sample databases; keep them as they are.");
	[_formContentView addSubview:_databaseField];

	_usernameLabel = [self makeLabel:NSLocalizedString(@"Username:", @"Connection form label for the database user name.")
							   frame:NSMakeRect(16, 166, 126, 20)
								bold:NO
						   alignment:NSTextAlignmentRight];
	[_formContentView addSubview:_usernameLabel];

	_usernameField = [[NSTextField alloc] initWithFrame:NSMakeRect(150, 162, 330, 24)];
	_usernameField.placeholderString = NSLocalizedString(@"Database user", @"Placeholder for the database user name field.");
	[_formContentView addSubview:_usernameField];

	_passwordLabel = [self makeLabel:NSLocalizedString(@"Password:", @"Connection form label for the database password.")
							   frame:NSMakeRect(16, 200, 126, 20)
								bold:NO
						   alignment:NSTextAlignmentRight];
	[_formContentView addSubview:_passwordLabel];

	_passwordField = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(150, 196, 330, 24)];
	_passwordField.placeholderString = NSLocalizedString(@"Database password", @"Placeholder for the database password field.");
	[_formContentView addSubview:_passwordField];

	_saveKeychainCheckbox = [NSButton checkboxWithTitle:NSLocalizedString(@"Save password in Keychain", @"Connection form checkbox. Use Apple's localized name for Keychain.")
												 target:nil
												 action:nil];
	_saveKeychainCheckbox.frame = NSMakeRect(150, 228, 260, 20);
	_saveKeychainCheckbox.state = NSControlStateValueOn;
	[_formContentView addSubview:_saveKeychainCheckbox];

	// Status & Spinner
	_spinner = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(24, 214, 16, 16)];
	_spinner.style = NSProgressIndicatorStyleSpinning;
	_spinner.displayedWhenStopped = NO;
	[content addSubview:_spinner];

	NSString *defaultStatus = _initialStatusPrompt.length > 0
		? _initialStatusPrompt
		: (isEditMode
			? NSLocalizedString(@"Verify or update the connection settings, then click Save & Refresh.", @"Connection window status prompt when editing an existing connection.")
			: NSLocalizedString(@"Select a database source to import its schema into a new .mad document.", @"Connection window status prompt when creating a report."));
	_statusLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(46, 210, 474, 34)];
	_statusLabel.editable = NO;
	_statusLabel.selectable = YES;
	_statusLabel.bezeled = NO;
	_statusLabel.drawsBackground = NO;
	_statusLabel.font = [NSFont systemFontOfSize:12.0];
	_statusLabel.textColor = (_initialStatusPrompt.length > 0) ? [NSColor labelColor] : [NSColor secondaryLabelColor];
	_statusLabel.usesSingleLineMode = NO;
	_statusLabel.cell.wraps = YES;
	_statusLabel.cell.scrollable = NO;
	_statusLabel.stringValue = defaultStatus;
	[content addSubview:_statusLabel];

	// Bottom Buttons
	_cancelButton = [NSButton buttonWithTitle:NSLocalizedString(@"Cancel", @"Connection window button that closes without saving.")
									   target:self
									   action:@selector(cancelAction:)];
	_cancelButton.frame = NSMakeRect(172, 250, 96, 28);
	_cancelButton.keyEquivalent = @"\033";
	[content addSubview:_cancelButton];

	_testButton = [NSButton buttonWithTitle:NSLocalizedString(@"Test Connection", @"Connection window button that tests the settings.")
									 target:self
									 action:@selector(testConnectionAction:)];
	_testButton.frame = NSMakeRect(276, 250, 124, 28);
	[content addSubview:_testButton];

	NSString *primaryTitle = isEditMode
		? NSLocalizedString(@"Save & Refresh", @"Connection window primary button when editing a connection.")
		: NSLocalizedString(@"Create Document…", @"Connection window primary button when creating a report.");
	_createButton = [NSButton buttonWithTitle:primaryTitle
									   target:self
									   action:@selector(createDocumentAction:)];
	_createButton.frame = NSMakeRect(408, 250, 116, 28);
	_createButton.keyEquivalent = @"\r";
	[content addSubview:_createButton];
}

- (void)populateFromDocument:(MADMacDocument *)document {
	MADDatabaseConnection *conn = document.headlessDocument.database.databaseConnection;
	RptqDatabaseCredentals *credRow = document.rptqDatabase.ownedByUser;
	MADDatabaseType dbType = (conn != nil) ? conn.databaseType : credRow.databaseType;

	switch (dbType) {
		case MADDatabaseTypeSqlite3:
			[_driverPopup selectItemAtIndex:MADMacDatabaseKindSQLite3];
			break;
		case MADDatabaseTypeMySQL:
			[_driverPopup selectItemAtIndex:MADMacDatabaseKindMySQL];
			break;
		case MADDatabaseTypeTDS:
			[_driverPopup selectItemAtIndex:MADMacDatabaseKindSQLServer];
			break;
		case MADDatabaseTypePostgres:
			[_driverPopup selectItemAtIndex:MADMacDatabaseKindPostgreSQL];
			break;
		default:
			[_driverPopup selectItemAtIndex:MADMacDatabaseKindSQLite3];
			break;
	}

	if (dbType == MADDatabaseTypeSqlite3) {
		NSString *path = nil;
		if ([conn conformsToProtocol:@protocol(MADDatabaseConnectionsPropertiesURL)]) {
			path = ((id <MADDatabaseConnectionsPropertiesURL>)conn).databaseUrl.path;
		}
		if (path.length == 0) {
			path = credRow.host.length > 0 ? credRow.host : credRow.dbname;
		}
		_sqlitePathField.stringValue = path ?: @"";
	} else {
		MADDatabaseConnection <MADConnectionsPropertiesProtocol> *sConn =
			[conn conformsToProtocol:@protocol(MADConnectionsPropertiesProtocol)]
			? (MADDatabaseConnection <MADConnectionsPropertiesProtocol> *)conn
			: nil;
		NSString *host = (sConn.host.length > 0) ? sConn.host : (credRow.host.length > 0 ? credRow.host : (sConn.server ?: @"127.0.0.1"));
		NSInteger port = (sConn.port > 0) ? sConn.port : (NSInteger)[credRow port];
		NSString *server = (sConn.server.length > 0) ? sConn.server : (credRow.server ?: @"");
		NSString *dbname = (sConn.database.length > 0) ? sConn.database : (credRow.dbname ?: @"");

		_hostField.stringValue = host ?: @"127.0.0.1";
		if (port > 0) {
			_portField.stringValue = [NSString stringWithFormat:@"%ld", (long)port];
		}
		_serverInstanceField.stringValue = server ?: @"";
		_databaseField.stringValue = dbname ?: @"";

		MADCredential *resolved = [document resolvedCredentialsForDatabaseConnection:conn];
		_usernameField.stringValue = resolved.username ?: @"";
		_passwordField.stringValue = resolved.password ?: @"";
	}
}

- (void)driverPopupChanged:(id) __unused sender {
	MADMacDatabaseKind kind = (MADMacDatabaseKind)_driverPopup.indexOfSelectedItem;
	switch (kind) {
		case MADMacDatabaseKindSQLite3:
			break;
		case MADMacDatabaseKindMySQL:
			if (_portField.integerValue == 0 || _portField.integerValue == 1433 || _portField.integerValue == 5432) {
				_portField.stringValue = @"3306";
			}
			break;
		case MADMacDatabaseKindSQLServer:
			if (_portField.integerValue == 0 || _portField.integerValue == 3306 || _portField.integerValue == 5432) {
				_portField.stringValue = @"1433";
			}
			break;
		case MADMacDatabaseKindPostgreSQL:
			if (_portField.integerValue == 0 || _portField.integerValue == 3306 || _portField.integerValue == 1433) {
				_portField.stringValue = @"5432";
			}
			break;
	}
	[self updateDriverSelectionAnimated:YES];
}

- (void)updateDriverSelection {
	[self updateDriverSelectionAnimated:NO];
}

- (void)updateDriverSelectionAnimated:(BOOL)animate {
	MADMacDatabaseKind kind = (MADMacDatabaseKind)_driverPopup.indexOfSelectedItem;
	BOOL isSQLite = (kind == MADMacDatabaseKindSQLite3);
	BOOL isSQLServer = (kind == MADMacDatabaseKindSQLServer);

	// Toggle visibility so irrelevant fields are completely hidden rather than left disabled
	_sqliteLabel.hidden = !isSQLite;
	_sqlitePathField.hidden = !isSQLite;
	_sqlitePathField.enabled = isSQLite;
	_browseSQLiteButton.hidden = !isSQLite;
	_browseSQLiteButton.enabled = isSQLite;
	_sqliteHintLabel.hidden = !isSQLite;

	_hostLabel.hidden = isSQLite;
	_hostField.hidden = isSQLite;
	_hostField.enabled = !isSQLite;
	_portLabel.hidden = isSQLite;
	_portField.hidden = isSQLite;
	_portField.enabled = !isSQLite;

	_serverInstanceLabel.hidden = !isSQLServer;
	_serverInstanceField.hidden = !isSQLServer;
	_serverInstanceField.enabled = isSQLServer;

	_databaseLabel.hidden = isSQLite;
	_databaseField.hidden = isSQLite;
	_databaseField.enabled = !isSQLite;

	_usernameLabel.hidden = isSQLite;
	_usernameField.hidden = isSQLite;
	_usernameField.enabled = !isSQLite;

	_passwordLabel.hidden = isSQLite;
	_passwordField.hidden = isSQLite;
	_passwordField.enabled = !isSQLite;

	_saveKeychainCheckbox.hidden = isSQLite;
	_saveKeychainCheckbox.enabled = !isSQLite;

	CGFloat boxHeight = 0;
	if (isSQLite) {
		_sqliteLabel.frame = NSMakeRect(16, 64, 126, 20);
		_sqlitePathField.frame = NSMakeRect(150, 60, 232, 24);
		_browseSQLiteButton.frame = NSMakeRect(388, 58, 96, 28);
		_sqliteHintLabel.frame = NSMakeRect(150, 88, 330, 16);
		boxHeight = 116.0;

		_sqlitePathField.nextKeyView = _browseSQLiteButton;
		_browseSQLiteButton.nextKeyView = _sqlitePathField;
	} else {
		CGFloat y = 60.0;
		_hostLabel.frame = NSMakeRect(16, y + 4, 126, 20);
		_hostField.frame = NSMakeRect(150, y, 212, 24);
		_portLabel.frame = NSMakeRect(366, y + 4, 38, 20);
		_portField.frame = NSMakeRect(410, y, 70, 24);
		y += 34.0;

		if (isSQLServer) {
			_serverInstanceLabel.frame = NSMakeRect(16, y + 4, 126, 20);
			_serverInstanceField.frame = NSMakeRect(150, y, 330, 24);
			y += 34.0;
		}

		_databaseLabel.frame = NSMakeRect(16, y + 4, 126, 20);
		_databaseField.frame = NSMakeRect(150, y, 330, 24);
		y += 34.0;

		_usernameLabel.frame = NSMakeRect(16, y + 4, 126, 20);
		_usernameField.frame = NSMakeRect(150, y, 330, 24);
		y += 34.0;

		_passwordLabel.frame = NSMakeRect(16, y + 4, 126, 20);
		_passwordField.frame = NSMakeRect(150, y, 330, 24);
		y += 32.0;

		_saveKeychainCheckbox.frame = NSMakeRect(150, y, 260, 20);
		y += 30.0;

		boxHeight = y;

		// Wire keyboard Tab loop across visible server fields
		_hostField.nextKeyView = _portField;
		if (isSQLServer) {
			_portField.nextKeyView = _serverInstanceField;
			_serverInstanceField.nextKeyView = _databaseField;
		} else {
			_portField.nextKeyView = _databaseField;
		}
		_databaseField.nextKeyView = _usernameField;
		_usernameField.nextKeyView = _passwordField;
		_passwordField.nextKeyView = _hostField;
	}

	_formContainerBox.frame = NSMakeRect(20, 62, 500, boxHeight);
	_formContentView.frame = NSMakeRect(0, 0, 500, boxHeight);

	CGFloat statusY = 62.0 + boxHeight + 10.0;
	_spinner.frame = NSMakeRect(24, statusY + 2.0, 16, 16);
	_statusLabel.frame = NSMakeRect(46, statusY, 474, 34);

	CGFloat buttonsY = statusY + 40.0;
	_cancelButton.frame = NSMakeRect(168, buttonsY, 96, 28);
	_testButton.frame = NSMakeRect(272, buttonsY, 126, 28);
	_createButton.frame = NSMakeRect(406, buttonsY, 118, 28);

	CGFloat desiredContentHeight = buttonsY + 44.0;
	NSRect oldWindowFrame = self.window.frame;
	NSRect newContentRect = NSMakeRect(0, 0, 540, desiredContentHeight);
	NSRect newWindowFrame = [self.window frameRectForContentRect:newContentRect];
	newWindowFrame.origin.x = oldWindowFrame.origin.x;
	newWindowFrame.origin.y = oldWindowFrame.origin.y + oldWindowFrame.size.height - newWindowFrame.size.height;
	[self.window setFrame:newWindowFrame display:YES animate:animate];

	if (!isSQLite) {
		if (_editingDocument != nil && _usernameField.stringValue.length > 0 && _passwordField.stringValue.length == 0) {
			[self.window makeFirstResponder:_passwordField];
		} else if (_editingDocument == nil) {
			[self.window makeFirstResponder:_hostField];
		}
	} else {
		[self.window makeFirstResponder:_sqlitePathField];
	}
}

- (void)browseSQLiteFile:(id) __unused sender {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	panel.title = NSLocalizedString(@"Choose SQLite 3 Database", @"Open panel title for choosing a SQLite database file. SQLite is a brand.");
	panel.canChooseFiles = YES;
	panel.canChooseDirectories = NO;
	panel.allowsMultipleSelection = NO;
	NSString *currentPath = [_sqlitePathField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (currentPath.length > 0) {
		NSString *dirPath = [currentPath stringByDeletingLastPathComponent];
		if ([[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
			panel.directoryURL = [NSURL fileURLWithPath:dirPath isDirectory:YES];
		}
	} else if (_editingDocument.fileURL.isFileURL) {
		panel.directoryURL = [_editingDocument.fileURL URLByDeletingLastPathComponent];
	}
	if ([panel runModal] == NSModalResponseOK && panel.URL.path.length > 0) {
		_sqlitePathField.stringValue = panel.URL.path;
	}
}

- (NSString *)formattedMessageForError:(NSError *)error fallback:(NSString *)fallback {
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

- (nullable MADDatabaseConnection *)buildConnectionWithCredentials:(MADCredential * _Nullable __autoreleasing * _Nullable)outCredentials
															 error:(NSError * _Nullable __autoreleasing * _Nullable)outError {
	MADMacDatabaseKind kind = (MADMacDatabaseKind)_driverPopup.indexOfSelectedItem;
	if (kind == MADMacDatabaseKindSQLite3) {
		NSString *path = [_sqlitePathField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		NSFileManager *fm = [NSFileManager defaultManager];
		BOOL isDir = NO;
		BOOL exists = (path.length > 0 && [fm fileExistsAtPath:path isDirectory:&isDir] && !isDir);
		unsigned long long fileSize = exists ? [[fm attributesOfItemAtPath:path error:nil] fileSize] : 0;
		if (!exists || fileSize == 0) {
			if (exists && fileSize == 0) {
				[fm removeItemAtPath:path error:nil];
			}
			if (outError != NULL) {
				NSString *msg = (path.length == 0)
					? NSLocalizedString(@"Please choose an existing SQLite database file.", @"Error: no SQLite database file was chosen.")
					: [[NSString alloc] initWithFormat:NSLocalizedString(@"No valid SQLite database file exists at %@.", @"Error: the chosen SQLite file is missing or empty. %@ is the path."), path];
				*outError = [NSError errorWithDomain:@"MADMacConnection"
												code:1
											userInfo:@{ NSLocalizedDescriptionKey: msg }];
			}
			return nil;
		}
		// Reference the user's selected SQLite file directly in place without copying into Application Support.
		NSURL *sourceURL = [NSURL fileURLWithPath:path isDirectory:NO];
		if (outCredentials != NULL) *outCredentials = nil;
		_lastCredentials = nil;
		return [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:sourceURL];
	}

	NSString *host = [_hostField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSString *database = [_databaseField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSInteger port = _portField.integerValue;
	NSString *user = [_usernameField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSString *password = _passwordField.stringValue ?: @"";

	if (host.length == 0 || database.length == 0) {
		if (outError != NULL) {
			*outError = [NSError errorWithDomain:@"MADMacConnection"
											code:2
										userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Host and Database Name are required.", @"Error: the connection form is missing its host or database name.") }];
		}
		return nil;
	}

	MADCredential *creds = [[MADCredential alloc] initWithUsername:user andPassword:password];
	_lastCredentials = creds;
	if (outCredentials != NULL) {
		*outCredentials = creds;
	}

	switch (kind) {
		case MADMacDatabaseKindMySQL:
			return [[MADDatabaseConnectionMySql alloc] initWithHost:host
														   database:database
															andPort:(port > 0 ? port : 3306)];
		case MADMacDatabaseKindSQLServer: {
			NSString *server = [_serverInstanceField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if (server.length == 0) server = host;
			return [[MADDatabaseConnectionSQLServer alloc] initWithHost:host
																 server:server
															   database:database
																andPort:(port > 0 ? port : 1433)];
		}
		case MADMacDatabaseKindPostgreSQL:
			return [[MADDatabaseConnectionPostgres alloc] initWithHost:host
															  database:database
															   andPort:(port > 0 ? port : 5432)];
		default:
			return nil;
	}
}

- (void)testConnectionAction:(id) __unused sender {
	NSError *buildError = nil;
	MADCredential *creds = nil;
	MADDatabaseConnection *conn = [self buildConnectionWithCredentials:&creds error:&buildError];
	if (conn == nil) {
		_statusLabel.textColor = [NSColor systemRedColor];
		_statusLabel.stringValue = [self formattedMessageForError:buildError fallback:NSLocalizedString(@"Invalid connection settings.", @"Connection status line: the settings are incomplete or invalid.")];
		return;
	}

	[_spinner startAnimation:nil];
	_statusLabel.textColor = [NSColor secondaryLabelColor];
	_statusLabel.stringValue = NSLocalizedString(@"Testing database connection…", @"Connection status line while the test runs.");

	MADDatabase *db = [MADDatabase newDatabaseWithConnection:conn];
	NSError *connError = nil;
	id handle = [db connectWithConnection:conn credentals:creds connectionError:&connError];
	[_spinner stopAnimation:nil];

	if (handle != nil && connError == nil) {
		NSError *tableError = nil;
		NSArray *tables = [db getTablesFromConnection:handle error:&tableError];
		[db closeConnection:handle];
		_statusLabel.textColor = [NSColor systemGreenColor];
		_statusLabel.stringValue = [[NSString alloc] initWithFormat:NSLocalizedString(@"Connected! Found %lu schema tables.", @"Connection status line: the test succeeded. %lu is the number of tables read."), (unsigned long)tables.count];
	} else {
		_statusLabel.textColor = [NSColor systemRedColor];
		_statusLabel.stringValue = [self formattedMessageForError:connError fallback:NSLocalizedString(@"Connection failed.", @"Connection status line: the connection failed with no more specific reason.")];
	}
}

- (BOOL)applyToEditingDocumentAndError:(NSError * _Nullable __autoreleasing * _Nullable)outError {
	if (_editingDocument == nil) {
		return NO;
	}
	NSError *buildError = nil;
	MADCredential *creds = nil;
	MADDatabaseConnection *conn = [self buildConnectionWithCredentials:&creds error:&buildError];
	if (conn == nil) {
		_statusLabel.textColor = [NSColor systemRedColor];
		_statusLabel.stringValue = [self formattedMessageForError:buildError fallback:NSLocalizedString(@"Invalid connection settings.", @"Connection status line: the settings are incomplete or invalid.")];
		if (outError != NULL) *outError = buildError;
		return NO;
	}

	[_spinner startAnimation:nil];
	_statusLabel.textColor = [NSColor secondaryLabelColor];
	_statusLabel.stringValue = NSLocalizedString(@"Verifying database connection…", @"Connection status line while saving the settings.");

	MADDatabase *db = [MADDatabase newDatabaseWithConnection:conn];
	NSError *connError = nil;
	id handle = [db connectWithConnection:conn credentals:creds connectionError:&connError];
	[_spinner stopAnimation:nil];

	if (handle == nil || connError != nil) {
		_statusLabel.textColor = [NSColor systemRedColor];
		_statusLabel.stringValue = [self formattedMessageForError:connError fallback:NSLocalizedString(@"Connection failed.", @"Connection status line: the connection failed with no more specific reason.")];
		if (outError != NULL) *outError = connError;
		return NO;
	}
	[db closeConnection:handle];

	BOOL saveKeychain = (_saveKeychainCheckbox.state == NSControlStateValueOn);
	[_editingDocument updateDatabaseConnection:conn
								   credentials:creds
								saveToKeychain:saveKeychain];
	return YES;
}

- (void)dismissWindowOrSheetWithCode:(NSModalResponse)code {
	if (self.window.sheetParent != nil) {
		[self.window.sheetParent endSheet:self.window returnCode:code];
	} else {
		[self.window close];
	}
}

- (void)createDocumentAction:(id) __unused sender {
	if (_editingDocument != nil) {
		NSError *applyErr = nil;
		if (![self applyToEditingDocumentAndError:&applyErr]) {
			return;
		}
		MADDatabaseConnection *updatedConn = _editingDocument.headlessDocument.database.databaseConnection;
		MADCredential *updatedCreds = _lastCredentials;
		[self dismissWindowOrSheetWithCode:NSModalResponseOK];
		if (self.onConnectionUpdated) {
			self.onConnectionUpdated(updatedConn, updatedCreds);
		}
		return;
	}

	NSError *buildError = nil;
	MADCredential *creds = nil;
	MADDatabaseConnection *conn = [self buildConnectionWithCredentials:&creds error:&buildError];
	if (conn == nil) {
		_statusLabel.textColor = [NSColor systemRedColor];
		_statusLabel.stringValue = [self formattedMessageForError:buildError fallback:NSLocalizedString(@"Invalid connection settings.", @"Connection status line: the settings are incomplete or invalid.")];
		return;
	}

	NSSavePanel *savePanel = [NSSavePanel savePanel];
	savePanel.title = NSLocalizedString(@"Save New Mobile Analytics Document (.mad)", @"Save panel title when creating a report. Mobile Analytics Document is the file type name.");
	savePanel.nameFieldStringValue = @"Untitled Report.mad";
	savePanel.canCreateDirectories = YES;
	if ([savePanel runModal] != NSModalResponseOK || savePanel.URL == nil) {
		return;
	}

	NSURL *destURL = savePanel.URL;
	if (![[destURL.pathExtension lowercaseString] isEqualToString:@"mad"]) {
		destURL = [destURL URLByAppendingPathExtension:@"mad"];
	}

	[_spinner startAnimation:nil];
	_statusLabel.textColor = [NSColor secondaryLabelColor];
	_statusLabel.stringValue = NSLocalizedString(@"Connecting and importing database schema…", @"Connection status line while the new report is created.");

	NSError *createError = nil;
	MADHeadlessDocument *doc = [MADHeadlessDocument createDocumentAtURL:destURL
												 withDatabaseConnection:conn
															credentials:creds
																  error:&createError];
	[_spinner stopAnimation:nil];

	if (doc == nil) {
		_statusLabel.textColor = [NSColor systemRedColor];
		_statusLabel.stringValue = [self formattedMessageForError:createError fallback:NSLocalizedString(@"Failed to create document.", @"Connection status line: the document could not be created.")];
		return;
	}

	if ([conn requiresCredentials] && creds != nil && creds.username.length > 0 &&
		_saveKeychainCheckbox.state == NSControlStateValueOn && conn.connectionString.length > 0) {
		[MADKeyChain saveUsername:creds.username andPassword:(creds.password ?: @"") forKey:conn.connectionString];
	}

	[self dismissWindowOrSheetWithCode:NSModalResponseOK];
	if (self.onDocumentCreated) {
		self.onDocumentCreated(doc, destURL);
	}
}

- (void)cancelAction:(id) __unused sender {
	[self dismissWindowOrSheetWithCode:NSModalResponseCancel];
}

@end
