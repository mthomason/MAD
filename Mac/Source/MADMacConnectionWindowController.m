//
//  MADMacConnectionWindowController.m
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMacConnectionWindowController.h"

#import <MAD/MAD.h>
#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADKeyChain.h>
#import <MADFoundation/MADURLFactory.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseConnection.h>
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

@interface MADMacConnectionWindowController ()

@property (nonatomic, strong) NSPopUpButton *driverPopup;
@property (nonatomic, strong) NSTextField *sqlitePathField;
@property (nonatomic, strong) NSButton *browseSQLiteButton;
@property (nonatomic, strong) NSButton *useChinookButton;

@property (nonatomic, strong) NSTextField *hostField;
@property (nonatomic, strong) NSTextField *portField;
@property (nonatomic, strong) NSTextField *serverInstanceField;
@property (nonatomic, strong) NSTextField *databaseField;
@property (nonatomic, strong) NSTextField *usernameField;
@property (nonatomic, strong) NSSecureTextField *passwordField;

@property (nonatomic, strong) NSTextField *statusLabel;
@property (nonatomic, strong) NSProgressIndicator *spinner;
@property (nonatomic, strong) NSButton *testButton;
@property (nonatomic, strong) NSButton *createButton;

@end

@implementation MADMacConnectionWindowController

- (instancetype)init {
	NSRect frame = NSMakeRect(0, 0, 540, 420);
	NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable;
	NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
												   styleMask:style
													 backing:NSBackingStoreBuffered
													   defer:NO];
	window.title = @"New Report from Database Connection";
	window.releasedWhenClosed = NO;
	[window center];

	if (self = [super initWithWindow:window]) {
		[self buildInterface];
		[self updateDriverSelection];
	}
	return self;
}

- (NSTextField *)makeLabel:(NSString *)text frame:(NSRect)frame bold:(BOOL)bold {
	NSTextField *label = [NSTextField labelWithString:text];
	label.frame = frame;
	label.font = bold ? [NSFont boldSystemFontOfSize:13.0] : [NSFont systemFontOfSize:12.5];
	return label;
}

- (void)buildInterface {
	NSView *content = self.window.contentView;

	[content addSubview:[self makeLabel:@"Create a New Mobile Analytics Document (.mad)"
								  frame:NSMakeRect(24, 376, 490, 22)
								   bold:YES]];

	[content addSubview:[self makeLabel:@"Database Driver:"
								  frame:NSMakeRect(24, 338, 130, 20)
								   bold:NO]];

	_driverPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(160, 334, 356, 26) pullsDown:NO];
	[_driverPopup addItemsWithTitles:@[
		@"SQLite 3 (Local File or Sample Database)",
		@"MySQL / MariaDB",
		@"Microsoft SQL Server (FreeTDS)",
		@"PostgreSQL (libpq)"
	]];
	_driverPopup.target = self;
	_driverPopup.action = @selector(driverPopupChanged:);
	[content addSubview:_driverPopup];

	// SQLite 3 section
	[content addSubview:[self makeLabel:@"SQLite Database:"
								  frame:NSMakeRect(24, 294, 130, 20)
								   bold:NO]];
	_sqlitePathField = [[NSTextField alloc] initWithFrame:NSMakeRect(160, 292, 260, 24)];
	_sqlitePathField.placeholderString = @"Path to .sqlite3 / .db file";
	[content addSubview:_sqlitePathField];

	_browseSQLiteButton = [NSButton buttonWithTitle:@"Browse…"
											 target:self
											 action:@selector(browseSQLiteFile:)];
	_browseSQLiteButton.frame = NSMakeRect(426, 290, 90, 28);
	[content addSubview:_browseSQLiteButton];

	_useChinookButton = [NSButton buttonWithTitle:@"Use Bundled Chinook Sample Database (chinook.sqlite3)"
										   target:self
										   action:@selector(useChinookDatabase:)];
	_useChinookButton.frame = NSMakeRect(160, 260, 356, 24);
	[content addSubview:_useChinookButton];

	// Server database fields
	[content addSubview:[self makeLabel:@"Host / Address:"
								  frame:NSMakeRect(24, 222, 130, 20)
								   bold:NO]];
	_hostField = [[NSTextField alloc] initWithFrame:NSMakeRect(160, 220, 230, 24)];
	_hostField.stringValue = @"127.0.0.1";
	[content addSubview:_hostField];

	[content addSubview:[self makeLabel:@"Port:"
								  frame:NSMakeRect(400, 222, 40, 20)
								   bold:NO]];
	_portField = [[NSTextField alloc] initWithFrame:NSMakeRect(444, 220, 72, 24)];
	_portField.stringValue = @"3306";
	[content addSubview:_portField];

	[content addSubview:[self makeLabel:@"Server Instance:"
								  frame:NSMakeRect(24, 188, 130, 20)
								   bold:NO]];
	_serverInstanceField = [[NSTextField alloc] initWithFrame:NSMakeRect(160, 186, 356, 24)];
	_serverInstanceField.placeholderString = @"Optional SQL Server instance name";
	[content addSubview:_serverInstanceField];

	[content addSubview:[self makeLabel:@"Database Name:"
								  frame:NSMakeRect(24, 154, 130, 20)
								   bold:NO]];
	_databaseField = [[NSTextField alloc] initWithFrame:NSMakeRect(160, 152, 356, 24)];
	_databaseField.placeholderString = @"e.g. Chinook, Northwind, postgres";
	[content addSubview:_databaseField];

	[content addSubview:[self makeLabel:@"Username:"
								  frame:NSMakeRect(24, 120, 130, 20)
								   bold:NO]];
	_usernameField = [[NSTextField alloc] initWithFrame:NSMakeRect(160, 118, 356, 24)];
	[content addSubview:_usernameField];

	[content addSubview:[self makeLabel:@"Password:"
								  frame:NSMakeRect(24, 86, 130, 20)
								   bold:NO]];
	_passwordField = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(160, 84, 356, 24)];
	[content addSubview:_passwordField];

	_spinner = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(24, 50, 16, 16)];
	_spinner.style = NSProgressIndicatorStyleSpinning;
	_spinner.displayedWhenStopped = NO;
	[content addSubview:_spinner];

	_statusLabel = [self makeLabel:@"Select a database source to import its schema into a new .mad document."
							 frame:NSMakeRect(48, 46, 468, 22)
							  bold:NO];
	_statusLabel.textColor = [NSColor secondaryLabelColor];
	[content addSubview:_statusLabel];

	NSButton *cancelButton = [NSButton buttonWithTitle:@"Cancel"
												target:self
												action:@selector(cancelAction:)];
	cancelButton.frame = NSMakeRect(184, 12, 96, 28);
	cancelButton.keyEquivalent = @"\033";
	[content addSubview:cancelButton];

	_testButton = [NSButton buttonWithTitle:@"Test Connection"
									 target:self
									 action:@selector(testConnectionAction:)];
	_testButton.frame = NSMakeRect(288, 12, 130, 28);
	[content addSubview:_testButton];

	_createButton = [NSButton buttonWithTitle:@"Create Document…"
									   target:self
									   action:@selector(createDocumentAction:)];
	_createButton.frame = NSMakeRect(424, 12, 100, 28);
	_createButton.keyEquivalent = @"\r";
	[content addSubview:_createButton];

	[self useChinookDatabase:nil];
}

- (void)driverPopupChanged:(id) __unused sender {
	[self updateDriverSelection];
}

- (void)updateDriverSelection {
	MADMacDatabaseKind kind = (MADMacDatabaseKind)_driverPopup.indexOfSelectedItem;
	BOOL isSQLite = (kind == MADMacDatabaseKindSQLite3);

	_sqlitePathField.enabled = isSQLite;
	_browseSQLiteButton.enabled = isSQLite;
	_useChinookButton.enabled = isSQLite;

	_hostField.enabled = !isSQLite;
	_portField.enabled = !isSQLite;
	_serverInstanceField.enabled = (kind == MADMacDatabaseKindSQLServer);
	_databaseField.enabled = !isSQLite;
	_usernameField.enabled = !isSQLite;
	_passwordField.enabled = !isSQLite;

	switch (kind) {
		case MADMacDatabaseKindSQLite3:
			break;
		case MADMacDatabaseKindMySQL:
			_portField.stringValue = @"3306";
			if (_databaseField.stringValue.length == 0) _databaseField.stringValue = @"Chinook";
			break;
		case MADMacDatabaseKindSQLServer:
			_portField.stringValue = @"1433";
			if (_databaseField.stringValue.length == 0) _databaseField.stringValue = @"Chinook";
			break;
		case MADMacDatabaseKindPostgreSQL:
			_portField.stringValue = @"5432";
			if (_databaseField.stringValue.length == 0) _databaseField.stringValue = @"chinook";
			break;
	}
}

- (nullable NSString *)resolvedChinookPath {
	NSString *bundled = [[NSBundle mainBundle] pathForResource:@"chinook" ofType:@"sqlite3"];
	if (bundled.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:bundled]) {
		return bundled;
	}
	NSURL *supportDir = [MADURLFactory newURLLocalApplicationSupportDirectoryForGroupID:[MADApplication groupIdentifier]];
	NSURL *installed = [supportDir URLByAppendingPathComponent:@"chinook.sqlite3"];
	if (installed.path.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:installed.path]) {
		return installed.path;
	}
	return nil;
}

- (void)useChinookDatabase:(id) __unused sender {
	NSString *chinook = [self resolvedChinookPath];
	if (chinook != nil) {
		_sqlitePathField.stringValue = chinook;
		_statusLabel.stringValue = @"Selected bundled Chinook SQLite3 sample database.";
	} else {
		_statusLabel.stringValue = @"Locate a SQLite3 database file using Browse…";
	}
}

- (void)browseSQLiteFile:(id) __unused sender {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	panel.title = @"Choose SQLite 3 Database";
	panel.canChooseFiles = YES;
	panel.canChooseDirectories = NO;
	panel.allowsMultipleSelection = NO;
	if ([panel runModal] == NSModalResponseOK && panel.URL.path.length > 0) {
		_sqlitePathField.stringValue = panel.URL.path;
	}
}

- (nullable MADDatabaseConnection *)buildConnectionWithCredentials:(MADCredential * _Nullable __autoreleasing *)outCredentials
															 error:(NSError * _Nullable __autoreleasing *)outError {
	MADMacDatabaseKind kind = (MADMacDatabaseKind)_driverPopup.indexOfSelectedItem;
	if (kind == MADMacDatabaseKindSQLite3) {
		NSString *path = [_sqlitePathField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if (path.length == 0 || ![[NSFileManager defaultManager] fileExistsAtPath:path]) {
			if (outError != NULL) {
				*outError = [NSError errorWithDomain:@"MADMacConnection"
												code:1
											userInfo:@{ NSLocalizedDescriptionKey: @"Please choose an existing SQLite3 database file." }];
			}
			return nil;
		}
		// Copy into Application Support so portable .mad references work seamlessly by filename
		NSURL *sourceURL = [NSURL fileURLWithPath:path];
		NSURL *supportDir = [MADURLFactory newURLLocalApplicationSupportDirectoryForGroupID:[MADApplication groupIdentifier]];
		[[NSFileManager defaultManager] createDirectoryAtURL:supportDir withIntermediateDirectories:YES attributes:nil error:NULL];
		NSURL *targetURL = [supportDir URLByAppendingPathComponent:sourceURL.lastPathComponent];
		if (![sourceURL.path isEqualToString:targetURL.path]) {
			[[NSFileManager defaultManager] removeItemAtURL:targetURL error:NULL];
			[[NSFileManager defaultManager] copyItemAtURL:sourceURL toURL:targetURL error:NULL];
		}
		if (outCredentials != NULL) *outCredentials = nil;
		return [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:targetURL];
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
										userInfo:@{ NSLocalizedDescriptionKey: @"Host and Database Name are required." }];
		}
		return nil;
	}

	if (outCredentials != NULL) {
		*outCredentials = [[MADCredential alloc] initWithUsername:user andPassword:password];
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
		_statusLabel.stringValue = buildError.localizedDescription ?: @"Invalid connection settings.";
		return;
	}

	[_spinner startAnimation:nil];
	_statusLabel.textColor = [NSColor secondaryLabelColor];
	_statusLabel.stringValue = @"Testing database connection…";

	MADDatabase *db = [MADDatabase newDatabaseWithConnection:conn];
	NSError *connError = nil;
	id handle = [db connectWithConnection:conn credentals:creds connectionError:&connError];
	[_spinner stopAnimation:nil];

	if (handle != nil && connError == nil) {
		NSError *tableError = nil;
		NSArray *tables = [db getTablesFromConnection:handle error:&tableError];
		[db closeConnection:handle];
		_statusLabel.textColor = [NSColor systemGreenColor];
		_statusLabel.stringValue = [NSString stringWithFormat:@"Connected! Found %lu schema tables.", (unsigned long)tables.count];
	} else {
		_statusLabel.textColor = [NSColor systemRedColor];
		_statusLabel.stringValue = connError.localizedDescription ?: @"Connection failed.";
	}
}

- (void)createDocumentAction:(id) __unused sender {
	NSError *buildError = nil;
	MADCredential *creds = nil;
	MADDatabaseConnection *conn = [self buildConnectionWithCredentials:&creds error:&buildError];
	if (conn == nil) {
		_statusLabel.textColor = [NSColor systemRedColor];
		_statusLabel.stringValue = buildError.localizedDescription ?: @"Invalid connection settings.";
		return;
	}

	NSSavePanel *savePanel = [NSSavePanel savePanel];
	savePanel.title = @"Save New Mobile Analytics Document (.mad)";
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
	_statusLabel.stringValue = @"Connecting and importing database schema…";

	NSError *createError = nil;
	MADHeadlessDocument *doc = [MADHeadlessDocument createDocumentAtURL:destURL
												 withDatabaseConnection:conn
															credentials:creds
																  error:&createError];
	[_spinner stopAnimation:nil];

	if (doc == nil) {
		_statusLabel.textColor = [NSColor systemRedColor];
		_statusLabel.stringValue = createError.localizedDescription ?: @"Failed to create document.";
		return;
	}

	if (creds != nil && creds.username.length > 0 && conn.identifier.length > 0) {
		[MADKeyChain saveUsername:creds.username andPassword:(creds.password ?: @"") forKey:conn.identifier];
	}

	[self.window close];
	if (self.onDocumentCreated) {
		self.onDocumentCreated(doc, destURL);
	}
}

- (void)cancelAction:(id) __unused sender {
	[self.window close];
}

@end
