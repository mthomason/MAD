//
//  MADMacQueryViewController.m
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMacQueryViewController.h"
#import "MADMacDocument.h"

#import <MAD/MAD.h>
#import "MADSQLQueryCompiler.h"
#import "MADSQLStatementResolver.h"
#import <MADSqlite3/MADDataTableFast.h>

@interface MADMacQueryViewController () <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, strong) NSTableView *schemaTablesTable;
@property (nonatomic, strong) NSTableView *queryTablesTable;
@property (nonatomic, strong) NSTableView *queryFieldsTable;
@property (nonatomic, strong) NSTableView *joinsTable;
@property (nonatomic, strong) NSTableView *predicatesTable;
@property (nonatomic, strong) NSTableView *groupsTable;
@property (nonatomic, strong) NSTableView *previewDataTable;

@property (nonatomic, strong) NSPopUpButton *joinLeftFieldPopup;
@property (nonatomic, strong) NSPopUpButton *joinTypePopup;
@property (nonatomic, strong) NSPopUpButton *joinRightFieldPopup;

@property (nonatomic, strong) NSPopUpButton *predicateFieldPopup;
@property (nonatomic, strong) NSPopUpButton *predicateOperatorPopup;
@property (nonatomic, strong) NSTextField *predicateValueField;

@property (nonatomic, strong) NSTextView *sqlTextView;
@property (nonatomic, strong) NSTextField *sqlStatusLabel;

@property (nonatomic, copy) NSArray<RptqDatabaseSchemaTable *> *schemaTables;
@property (nonatomic, copy) NSArray<RptqQueryTable *> *queryTables;
@property (nonatomic, copy) NSArray<RptqQueryField *> *queryFields;
@property (nonatomic, copy) NSArray<RptqQueryLinks *> *queryLinks;
@property (nonatomic, copy) NSArray<RptqQueryPredicate *> *queryPredicates;
@property (nonatomic, copy) NSArray<RptqQueryGroup *> *queryGroups;

@end

@implementation MADMacQueryViewController

- (instancetype)initWithDocument:(MADMacDocument *)document {
	if (self = [super initWithNibName:nil bundle:nil]) {
		_document = document;
		_schemaTables = @[];
		_queryTables = @[];
		_queryFields = @[];
		_queryLinks = @[];
		_queryPredicates = @[];
		_queryGroups = @[];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSTableView *)makeSingleColumnTableWithHeader:(NSString *)title identifier:(NSString *)ident {
	NSTableView *tv = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, 260, 140)];
	tv.usesAlternatingRowBackgroundColors = YES;
	tv.rowHeight = 22.0;
	tv.delegate = self;
	tv.dataSource = self;
	NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:ident];
	col.title = title;
	col.width = 240.0;
	[tv addTableColumn:col];
	return tv;
}

- (NSScrollView *)wrapTableInScroll:(NSTableView *)table {
	NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 260, 140)];
	scroll.hasVerticalScroller = YES;
	scroll.hasHorizontalScroller = YES;
	scroll.borderType = NSBezelBorder;
	scroll.documentView = table;
	scroll.translatesAutoresizingMaskIntoConstraints = NO;
	return scroll;
}

- (void)loadView {
	NSSplitView *rootSplit = [[NSSplitView alloc] initWithFrame:NSMakeRect(0, 0, 1180, 740)];
	rootSplit.vertical = YES;
	rootSplit.dividerStyle = NSSplitViewDividerStyleThin;
	rootSplit.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

	// Left Pane: Visual Query Builder
	NSView *leftPane = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 620, 740)];
	leftPane.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

	// Right Pane: SQL Studio + Data Preview
	NSView *rightPane = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 560, 740)];
	rightPane.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

	[self populateLeftPane:leftPane];
	[self populateRightPane:rightPane];

	[rootSplit addSubview:leftPane];
	[rootSplit addSubview:rightPane];
	[rootSplit adjustSubviews];
	[rootSplit setPosition:620 ofDividerAtIndex:0];

	self.view = rootSplit;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleDocumentNotification:)
												 name:MADMacDocumentDidMutateNotification
											   object:_document];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleDocumentNotification:)
												 name:MADMacDocumentDidRefreshNotification
											   object:_document];
	[self reloadFromDocument];
}

- (void)handleDocumentNotification:(NSNotification *) __unused note {
	[self reloadFromDocument];
}

- (void)populateLeftPane:(NSView *)container {
	// Top row: Schema Tables + Query Tables + Query Fields
	_schemaTablesTable = [self makeSingleColumnTableWithHeader:@"Database Schema Tables" identifier:@"schema"];
	NSScrollView *schemaScroll = [self wrapTableInScroll:_schemaTablesTable];

	NSButton *addTableBtn = [NSButton buttonWithTitle:@"+ Add Table to Query"
											   target:self
											   action:@selector(addSelectedSchemaTable:)];

	_queryTablesTable = [self makeSingleColumnTableWithHeader:@"Tables in Query" identifier:@"qtable"];
	NSScrollView *queryTablesScroll = [self wrapTableInScroll:_queryTablesTable];

	NSButton *removeTableBtn = [NSButton buttonWithTitle:@"- Remove Table"
												  target:self
												  action:@selector(removeSelectedQueryTable:)];

	_queryFieldsTable = [self makeSingleColumnTableWithHeader:@"Query Fields ([x] SELECT | Table.Column)" identifier:@"qfield"];
	_queryFieldsTable.doubleAction = @selector(toggleSelectedQueryField:);
	_queryFieldsTable.target = self;
	NSScrollView *queryFieldsScroll = [self wrapTableInScroll:_queryFieldsTable];

	NSButton *toggleFieldBtn = [NSButton buttonWithTitle:@"Toggle SELECT"
												  target:self
												  action:@selector(toggleSelectedQueryField:)];
	NSButton *selectAllFieldsBtn = [NSButton buttonWithTitle:@"Select All"
													  target:self
													  action:@selector(selectAllQueryFields:)];
	NSButton *addGroupBtn = [NSButton buttonWithTitle:@"+ Group By Field"
											   target:self
											   action:@selector(addGroupForSelectedField:)];

	// Bottom section: TabView for Joins, Where Filters, and Groupings
	NSTabView *clausesTabs = [[NSTabView alloc] initWithFrame:NSMakeRect(0, 0, 580, 260)];
	clausesTabs.translatesAutoresizingMaskIntoConstraints = NO;

	// Tab 1: Joins
	NSTabViewItem *joinsTab = [[NSTabViewItem alloc] initWithIdentifier:@"joins"];
	joinsTab.label = @"Table Joins (ON)";
	NSView *joinsView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 560, 220)];
	_joinsTable = [self makeSingleColumnTableWithHeader:@"Active Table Joins" identifier:@"join"];
	NSScrollView *joinsScroll = [self wrapTableInScroll:_joinsTable];

	_joinLeftFieldPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	_joinTypePopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	[_joinTypePopup addItemsWithTitles:@[@"INNER JOIN", @"LEFT OUTER JOIN", @"RIGHT OUTER JOIN", @"FULL OUTER JOIN"]];
	_joinRightFieldPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	NSButton *addJoinBtn = [NSButton buttonWithTitle:@"+ Add Join" target:self action:@selector(addJoinAction:)];
	NSButton *removeJoinBtn = [NSButton buttonWithTitle:@"- Remove Join" target:self action:@selector(removeJoinAction:)];

	NSStackView *joinControls = [NSStackView stackViewWithViews:@[_joinLeftFieldPopup, _joinTypePopup, _joinRightFieldPopup, addJoinBtn, removeJoinBtn]];
	joinControls.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	joinControls.spacing = 6.0;
	joinControls.translatesAutoresizingMaskIntoConstraints = NO;
	[joinsView addSubview:joinsScroll];
	[joinsView addSubview:joinControls];
	[NSLayoutConstraint activateConstraints:@[
		[joinControls.topAnchor constraintEqualToAnchor:joinsView.topAnchor constant:8],
		[joinControls.leadingAnchor constraintEqualToAnchor:joinsView.leadingAnchor constant:8],
		[joinControls.trailingAnchor constraintLessThanOrEqualToAnchor:joinsView.trailingAnchor constant:-8],
		[joinsScroll.topAnchor constraintEqualToAnchor:joinControls.bottomAnchor constant:8],
		[joinsScroll.leadingAnchor constraintEqualToAnchor:joinsView.leadingAnchor constant:8],
		[joinsScroll.trailingAnchor constraintEqualToAnchor:joinsView.trailingAnchor constant:-8],
		[joinsScroll.bottomAnchor constraintEqualToAnchor:joinsView.bottomAnchor constant:-8],
	]];
	joinsTab.view = joinsView;
	[clausesTabs addTabViewItem:joinsTab];

	// Tab 2: Filters (WHERE)
	NSTabViewItem *predTab = [[NSTabViewItem alloc] initWithIdentifier:@"predicates"];
	predTab.label = @"Filters (WHERE)";
	NSView *predView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 560, 220)];
	_predicatesTable = [self makeSingleColumnTableWithHeader:@"Active WHERE Predicates" identifier:@"pred"];
	NSScrollView *predScroll = [self wrapTableInScroll:_predicatesTable];

	_predicateFieldPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	_predicateOperatorPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	[_predicateOperatorPopup addItemsWithTitles:@[@"=", @"!=", @"<", @"<=", @">", @">="]];
	_predicateValueField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 140, 24)];
	_predicateValueField.placeholderString = @"Filter value (e.g. London)";
	[_predicateValueField.widthAnchor constraintGreaterThanOrEqualToConstant:130].active = YES;
	NSButton *addPredBtn = [NSButton buttonWithTitle:@"+ Add Filter" target:self action:@selector(addPredicateAction:)];
	NSButton *removePredBtn = [NSButton buttonWithTitle:@"- Remove Filter" target:self action:@selector(removePredicateAction:)];

	NSStackView *predControls = [NSStackView stackViewWithViews:@[_predicateFieldPopup, _predicateOperatorPopup, _predicateValueField, addPredBtn, removePredBtn]];
	predControls.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	predControls.spacing = 6.0;
	predControls.translatesAutoresizingMaskIntoConstraints = NO;
	[predView addSubview:predScroll];
	[predView addSubview:predControls];
	[NSLayoutConstraint activateConstraints:@[
		[predControls.topAnchor constraintEqualToAnchor:predView.topAnchor constant:8],
		[predControls.leadingAnchor constraintEqualToAnchor:predView.leadingAnchor constant:8],
		[predControls.trailingAnchor constraintLessThanOrEqualToAnchor:predView.trailingAnchor constant:-8],
		[predScroll.topAnchor constraintEqualToAnchor:predControls.bottomAnchor constant:8],
		[predScroll.leadingAnchor constraintEqualToAnchor:predView.leadingAnchor constant:8],
		[predScroll.trailingAnchor constraintEqualToAnchor:predView.trailingAnchor constant:-8],
		[predScroll.bottomAnchor constraintEqualToAnchor:predView.bottomAnchor constant:-8],
	]];
	predTab.view = predView;
	[clausesTabs addTabViewItem:predTab];

	// Tab 3: Groupings (GROUP BY)
	NSTabViewItem *groupsTab = [[NSTabViewItem alloc] initWithIdentifier:@"groups"];
	groupsTab.label = @"Groupings (GROUP BY)";
	NSView *groupsView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 560, 220)];
	_groupsTable = [self makeSingleColumnTableWithHeader:@"Report Grouping Levels (GROUP BY)" identifier:@"group"];
	NSScrollView *groupsScroll = [self wrapTableInScroll:_groupsTable];
	NSButton *removeGroupBtn = [NSButton buttonWithTitle:@"- Remove Selected Group"
												  target:self
												  action:@selector(removeSelectedGroupAction:)];
	removeGroupBtn.translatesAutoresizingMaskIntoConstraints = NO;
	[groupsView addSubview:removeGroupBtn];
	[groupsView addSubview:groupsScroll];
	[NSLayoutConstraint activateConstraints:@[
		[removeGroupBtn.topAnchor constraintEqualToAnchor:groupsView.topAnchor constant:8],
		[removeGroupBtn.leadingAnchor constraintEqualToAnchor:groupsView.leadingAnchor constant:8],
		[groupsScroll.topAnchor constraintEqualToAnchor:removeGroupBtn.bottomAnchor constant:8],
		[groupsScroll.leadingAnchor constraintEqualToAnchor:groupsView.leadingAnchor constant:8],
		[groupsScroll.trailingAnchor constraintEqualToAnchor:groupsView.trailingAnchor constant:-8],
		[groupsScroll.bottomAnchor constraintEqualToAnchor:groupsView.bottomAnchor constant:-8],
	]];
	groupsTab.view = groupsView;
	[clausesTabs addTabViewItem:groupsTab];

	// Assemble Left Stack
	NSStackView *schemaCol = [NSStackView stackViewWithViews:@[schemaScroll, addTableBtn]];
	schemaCol.orientation = NSUserInterfaceLayoutOrientationVertical;
	schemaCol.alignment = NSLayoutAttributeLeading;
	schemaCol.spacing = 6.0;

	NSStackView *qTableCol = [NSStackView stackViewWithViews:@[queryTablesScroll, removeTableBtn]];
	qTableCol.orientation = NSUserInterfaceLayoutOrientationVertical;
	qTableCol.alignment = NSLayoutAttributeLeading;
	qTableCol.spacing = 6.0;

	NSStackView *fieldBtns = [NSStackView stackViewWithViews:@[toggleFieldBtn, selectAllFieldsBtn, addGroupBtn]];
	fieldBtns.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	fieldBtns.spacing = 6.0;

	NSStackView *qFieldCol = [NSStackView stackViewWithViews:@[queryFieldsScroll, fieldBtns]];
	qFieldCol.orientation = NSUserInterfaceLayoutOrientationVertical;
	qFieldCol.alignment = NSLayoutAttributeLeading;
	qFieldCol.spacing = 6.0;

	NSStackView *topRow = [NSStackView stackViewWithViews:@[schemaCol, qTableCol, qFieldCol]];
	topRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	topRow.distribution = NSStackViewDistributionFillEqually;
	topRow.spacing = 10.0;
	topRow.translatesAutoresizingMaskIntoConstraints = NO;

	[container addSubview:topRow];
	[container addSubview:clausesTabs];

	[NSLayoutConstraint activateConstraints:@[
		[topRow.topAnchor constraintEqualToAnchor:container.topAnchor constant:12],
		[topRow.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:12],
		[topRow.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-12],
		[topRow.heightAnchor constraintGreaterThanOrEqualToConstant:340],

		[clausesTabs.topAnchor constraintEqualToAnchor:topRow.bottomAnchor constant:12],
		[clausesTabs.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:12],
		[clausesTabs.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-12],
		[clausesTabs.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-12],
		[clausesTabs.heightAnchor constraintEqualToConstant:250],
	]];
}

- (void)populateRightPane:(NSView *)container {
	NSTextField *sqlTitle = [NSTextField labelWithString:@"SQL Studio (Live Generated SQL & Direct SQL Entry)"];
	sqlTitle.font = [NSFont boldSystemFontOfSize:13.0];
	sqlTitle.translatesAutoresizingMaskIntoConstraints = NO;

	NSScrollView *sqlScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 520, 220)];
	sqlScroll.hasVerticalScroller = YES;
	sqlScroll.borderType = NSBezelBorder;
	sqlScroll.translatesAutoresizingMaskIntoConstraints = NO;

	_sqlTextView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 520, 220)];
	_sqlTextView.editable = YES;
	_sqlTextView.richText = NO;
	_sqlTextView.automaticQuoteSubstitutionEnabled = NO;
	_sqlTextView.automaticDashSubstitutionEnabled = NO;
	_sqlTextView.font = [NSFont monospacedSystemFontOfSize:12.5 weight:NSFontWeightRegular];
	_sqlTextView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	sqlScroll.documentView = _sqlTextView;

	NSButton *syncSQLBtn = [NSButton buttonWithTitle:@"Sync from Visual Query"
											  target:self
											  action:@selector(syncSQLFromVisualQuery:)];
	NSButton *applySQLBtn = [NSButton buttonWithTitle:@"Compile & Apply SQL to Document"
											   target:self
											   action:@selector(compileAndApplySQL:)];
	NSButton *refreshPreviewBtn = [NSButton buttonWithTitle:@"Refresh Query Results"
													 target:self
													 action:@selector(refreshPreviewData:)];

	NSStackView *sqlButtons = [NSStackView stackViewWithViews:@[syncSQLBtn, applySQLBtn, refreshPreviewBtn]];
	sqlButtons.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	sqlButtons.spacing = 8.0;
	sqlButtons.translatesAutoresizingMaskIntoConstraints = NO;

	_sqlStatusLabel = [NSTextField labelWithString:@"Ready."];
	_sqlStatusLabel.font = [NSFont systemFontOfSize:12.0];
	_sqlStatusLabel.textColor = [NSColor secondaryLabelColor];
	_sqlStatusLabel.lineBreakMode = NSLineBreakByTruncatingTail;
	_sqlStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;

	NSTextField *previewTitle = [NSTextField labelWithString:@"Cached Result Set Preview (MADDataTableFast)"];
	previewTitle.font = [NSFont boldSystemFontOfSize:13.0];
	previewTitle.translatesAutoresizingMaskIntoConstraints = NO;

	_previewDataTable = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, 520, 320)];
	_previewDataTable.usesAlternatingRowBackgroundColors = YES;
	_previewDataTable.rowHeight = 20.0;
	_previewDataTable.delegate = self;
	_previewDataTable.dataSource = self;
	NSScrollView *previewScroll = [self wrapTableInScroll:_previewDataTable];

	[container addSubview:sqlTitle];
	[container addSubview:sqlScroll];
	[container addSubview:sqlButtons];
	[container addSubview:_sqlStatusLabel];
	[container addSubview:previewTitle];
	[container addSubview:previewScroll];

	[NSLayoutConstraint activateConstraints:@[
		[sqlTitle.topAnchor constraintEqualToAnchor:container.topAnchor constant:12],
		[sqlTitle.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:12],

		[sqlScroll.topAnchor constraintEqualToAnchor:sqlTitle.bottomAnchor constant:6],
		[sqlScroll.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:12],
		[sqlScroll.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-12],
		[sqlScroll.heightAnchor constraintEqualToConstant:200],

		[sqlButtons.topAnchor constraintEqualToAnchor:sqlScroll.bottomAnchor constant:8],
		[sqlButtons.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:12],

		[_sqlStatusLabel.topAnchor constraintEqualToAnchor:sqlButtons.bottomAnchor constant:6],
		[_sqlStatusLabel.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:12],
		[_sqlStatusLabel.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-12],

		[previewTitle.topAnchor constraintEqualToAnchor:_sqlStatusLabel.bottomAnchor constant:12],
		[previewTitle.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:12],

		[previewScroll.topAnchor constraintEqualToAnchor:previewTitle.bottomAnchor constant:6],
		[previewScroll.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:12],
		[previewScroll.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-12],
		[previewScroll.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-12],
	]];
}

#pragma mark - Reloading Model

- (void)reloadFromDocument {
	RptqDatabase *db = _document.rptqDatabase;
	RptqQuery *query = _document.rptqQuery;

	NSSortDescriptor *byName = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
	_schemaTables = [db.hasTables sortedArrayUsingDescriptors:@[byName]] ?: @[];

	NSSortDescriptor *byDrop = [NSSortDescriptor sortDescriptorWithKey:@"dropIndex" ascending:YES];
	_queryTables = [query.hasQueryTables sortedArrayUsingDescriptors:@[byDrop]] ?: @[];

	NSMutableArray<RptqQueryField *> *fields = [[NSMutableArray alloc] init];
	for (RptqQueryTable *qt in _queryTables) {
		NSSortDescriptor *fSort = [NSSortDescriptor sortDescriptorWithKey:@"databaseSchemaField.name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
		NSArray<RptqQueryField *> *sorted = [qt.hasQueryFields sortedArrayUsingDescriptors:@[fSort]] ?: @[];
		[fields addObjectsFromArray:sorted];
	}
	_queryFields = fields;

	_queryLinks = [query.hasQueryLinks allObjects] ?: @[];
	_queryPredicates = [query.hasQueryPredicate allObjects] ?: @[];
	_queryGroups = [query sortedQueryGroups] ?: @[];

	[_schemaTablesTable reloadData];
	[_queryTablesTable reloadData];
	[_queryFieldsTable reloadData];
	[_joinsTable reloadData];
	[_predicatesTable reloadData];
	[_groupsTable reloadData];

	[self rebuildFieldPopups];
	[self syncSQLFromVisualQuery:nil];
	[self rebuildPreviewColumnsAndReload];
}

- (void)rebuildFieldPopups {
	[_joinLeftFieldPopup removeAllItems];
	[_joinRightFieldPopup removeAllItems];
	[_predicateFieldPopup removeAllItems];

	for (RptqQueryField *qf in _queryFields) {
		NSString *label = [NSString stringWithFormat:@"%@.%@", qf.inQueryTable.alias ?: qf.inQueryTable.databaseSchemaTable.name, qf.databaseSchemaField.name];
		[_joinLeftFieldPopup addItemWithTitle:label];
		_joinLeftFieldPopup.lastItem.tag = (NSInteger)qf.identifier;
		[_joinRightFieldPopup addItemWithTitle:label];
		_joinRightFieldPopup.lastItem.tag = (NSInteger)qf.identifier;
		[_predicateFieldPopup addItemWithTitle:label];
		_predicateFieldPopup.lastItem.tag = (NSInteger)qf.identifier;
	}
}

- (void)rebuildPreviewColumnsAndReload {
	while (_previewDataTable.tableColumns.count > 0) {
		[_previewDataTable removeTableColumn:_previewDataTable.tableColumns.lastObject];
	}
	MADDataTableFast *dt = _document.headlessDocument.dataTable;
	NSArray<NSString *> *keys = dt.columnKeys ?: @[];
	for (NSString *key in keys) {
		NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:key];
		col.title = key;
		col.width = 120.0;
		[_previewDataTable addTableColumn:col];
	}
	[_previewDataTable reloadData];
}

#pragma mark - Actions

- (void)addSelectedSchemaTable:(id) __unused sender {
	NSInteger row = _schemaTablesTable.selectedRow;
	if (row < 0 || (NSUInteger)row >= _schemaTables.count) return;
	RptqDatabaseSchemaTable *schemaTable = _schemaTables[(NSUInteger)row];
	RptqDatabase *db = _document.rptqDatabase;
	RptqStoreContext *ctx = _document.managedObjectContext;
	if (db == nil || ctx == nil) return;

	[RptqQueryTable newQueryTableForSchemaTable:schemaTable
									   database:db
						forManagedObjectContext:ctx];
	[_document notifyDocumentMutated];
}

- (void)removeSelectedQueryTable:(id) __unused sender {
	NSInteger row = _queryTablesTable.selectedRow;
	if (row < 0 || (NSUInteger)row >= _queryTables.count) return;
	RptqQueryTable *qt = _queryTables[(NSUInteger)row];
	RptqStoreContext *ctx = _document.managedObjectContext;
	RptqQuery *query = _document.rptqQuery;
	if (ctx == nil || query == nil) return;

	[_document.headlessDocument deleteDatafieldsRelatedToTable:qt.identifier inContent:ctx];
	[_document.headlessDocument deleteAggregateFieldRelatedToTable:qt.identifier inContent:ctx];

	for (RptqQueryLinks *link in [query.hasQueryLinks copy]) {
		if ([link isConnectedToTable:qt]) {
			[query removeHasQueryLinksObject:link];
			[ctx deleteObject:link error:NULL];
		}
	}
	for (RptqQueryField *qf in [qt.hasQueryFields copy]) {
		[ctx deleteObject:qf error:NULL];
	}
	[query removeHasQueryTablesObject:qt];
	[ctx deleteObject:qt error:NULL];
	[_document notifyDocumentMutated];
}

- (void)toggleSelectedQueryField:(id) __unused sender {
	NSInteger row = _queryFieldsTable.selectedRow;
	if (row < 0 || (NSUInteger)row >= _queryFields.count) return;
	RptqQueryField *qf = _queryFields[(NSUInteger)row];
	RptqQuery *query = _document.rptqQuery;
	if (qf.databaseSchemaField != nil && query != nil) {
		if ([query.hasFields containsObject:qf.databaseSchemaField]) {
			[query removeHasFieldsObject:qf.databaseSchemaField];
		} else {
			[query addHasFieldsObject:qf.databaseSchemaField];
		}
	}
	[_document notifyDocumentMutated];
}

- (void)selectAllQueryFields:(id) __unused sender {
	RptqQuery *query = _document.rptqQuery;
	for (RptqQueryField *qf in _queryFields) {
		if (qf.databaseSchemaField != nil) {
			[query addHasFieldsObject:qf.databaseSchemaField];
		}
	}
	[_document notifyDocumentMutated];
}

- (void)addGroupForSelectedField:(id) __unused sender {
	NSInteger row = _queryFieldsTable.selectedRow;
	if (row < 0 || (NSUInteger)row >= _queryFields.count) return;
	RptqQueryField *qf = _queryFields[(NSUInteger)row];
	[_document.headlessDocument addQueryGroupWithQueryField:qf.identifier
											   andSortOrder:MADSortOrderAccending];
	[_document notifyDocumentMutated];
}

- (void)removeSelectedGroupAction:(id) __unused sender {
	NSInteger row = _groupsTable.selectedRow;
	if (row < 0 || (NSUInteger)row >= _queryGroups.count) return;
	RptqQueryGroup *group = _queryGroups[(NSUInteger)row];
	[_document.headlessDocument removeGroupWitObjectID:group.identifier
							  fromManagedObjectContext:_document.managedObjectContext];
	[_document notifyDocumentMutated];
}

- (void)addJoinAction:(id) __unused sender {
	NSMenuItem *leftItem = _joinLeftFieldPopup.selectedItem;
	NSMenuItem *rightItem = _joinRightFieldPopup.selectedItem;
	if (leftItem == nil || rightItem == nil || leftItem.tag == rightItem.tag) return;

	RptqStoreContext *ctx = _document.managedObjectContext;
	RptqQueryField *leftField = [RptqQueryField queryFieldForObjectID:leftItem.tag managedObjectContext:ctx];
	RptqQueryField *rightField = [RptqQueryField queryFieldForObjectID:rightItem.tag managedObjectContext:ctx];
	if (leftField == nil || rightField == nil) return;

	MADLinkType linkType = MADLinkTypeInnerJoin;
	switch (_joinTypePopup.indexOfSelectedItem) {
		case 1: linkType = MADLinkTypeLeftOuterJoin; break;
		case 2: linkType = MADLinkTypeRightOuterJoin; break;
		case 3: linkType = MADLinkTypeFullOuterJoin; break;
		default: linkType = MADLinkTypeInnerJoin; break;
	}
	[RptqQueryLinks newQueryLinksWithLeftField:leftField
									rightField:rightField
									  joinType:linkType
						  managedObjectContext:ctx];
	[_document notifyDocumentMutated];
}

- (void)removeJoinAction:(id) __unused sender {
	NSInteger row = _joinsTable.selectedRow;
	if (row < 0 || (NSUInteger)row >= _queryLinks.count) return;
	RptqQueryLinks *link = _queryLinks[(NSUInteger)row];
	[_document.rptqQuery removeHasQueryLinksObject:link];
	[_document.managedObjectContext deleteObject:link error:NULL];
	[_document notifyDocumentMutated];
}

- (void)addPredicateAction:(id) __unused sender {
	NSMenuItem *fieldItem = _predicateFieldPopup.selectedItem;
	NSString *value = _predicateValueField.stringValue ?: @"";
	if (fieldItem == nil || value.length == 0) return;

	MADPredicateOperator op = MADPredicateOperatorEqual;
	switch (_predicateOperatorPopup.indexOfSelectedItem) {
		case 1: op = MADPredicateOperatorNotEqual; break;
		case 2: op = MADPredicateOperatorLessThan; break;
		case 3: op = MADPredicateOperatorLessThanOrEqualTo; break;
		case 4: op = MADPredicateOperatorGreaterThan; break;
		case 5: op = MADPredicateOperatorGreaterThanOrEqualTo; break;
		default: op = MADPredicateOperatorEqual; break;
	}

	NSError *err = nil;
	[RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID:fieldItem.tag
											  comparsonOperator:op
												  andRightValue:value
										forManagedObjectContext:_document.managedObjectContext
														  error:&err];
	if (err == nil) {
		_predicateValueField.stringValue = @"";
		[_document notifyDocumentMutated];
	} else {
		_sqlStatusLabel.textColor = [NSColor systemRedColor];
		_sqlStatusLabel.stringValue = err.localizedDescription ?: @"Could not add predicate.";
	}
}

- (void)removePredicateAction:(id) __unused sender {
	NSInteger row = _predicatesTable.selectedRow;
	if (row < 0 || (NSUInteger)row >= _queryPredicates.count) return;
	RptqQueryPredicate *pred = _queryPredicates[(NSUInteger)row];
	[RptqQueryPredicate deletePredicate:pred];
	[_document notifyDocumentMutated];
}

- (void)syncSQLFromVisualQuery:(id) __unused sender {
	[_document.headlessDocument invalidateQueryAndModelCaches];
	NSError *sqlErr = nil;
	NSString *generated = [_document.headlessDocument.mainQuery copySQLWithManagedObjectContext:_document.managedObjectContext
																						  error:&sqlErr];
	if (generated.length == 0) {
		NSError *allFieldsErr = nil;
		generated = [_document.headlessDocument.mainQuery SQLOnlyActiveFields:NO
														 managedObjectContext:_document.managedObjectContext
																		error:&allFieldsErr];
	}
	if (generated.length == 0) {
		generated = _document.rptqQuery.sqlSourceText ?: @"-- Add one or more tables on the left or type a SELECT query here.";
	}
	_sqlTextView.string = generated;
}

- (void)compileAndApplySQL:(id) __unused sender {
	NSString *sql = [_sqlTextView.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (sql.length == 0) return;

	RptqDatabase *db = _document.rptqDatabase;
	RptqQuery *query = _document.rptqQuery;
	RptqStoreContext *ctx = _document.managedObjectContext;
	MADHeadlessDocument *headless = _document.headlessDocument;
	if (db == nil || query == nil || ctx == nil || headless == nil) return;

	NSMutableDictionary<NSString *, NSArray<NSString *> *> *schemaMap = [[NSMutableDictionary alloc] init];
	for (RptqDatabaseSchemaTable *st in db.hasTables) {
		if (st.name.length == 0) continue;
		NSMutableArray<NSString *> *cols = [[NSMutableArray alloc] init];
		for (RptqDatabaseSchemaField *sf in st.hasFields) {
			if (sf.name.length > 0) [cols addObject:sf.name];
		}
		schemaMap[st.name] = cols;
	}

	NSError *parseError = nil;
	MADSQLParser *parser = [[MADSQLParser alloc] initWithSQL:sql
								   identifierQuoteCharacters:@"\"\""
													  schema:schemaMap];
	MADSQLStatement *statement = [parser parseStatement:&parseError];
	if (statement == nil) {
		_sqlStatusLabel.textColor = [NSColor systemRedColor];
		_sqlStatusLabel.stringValue = [NSString stringWithFormat:@"SQL Parse Error: %@", parseError.localizedDescription];
		return;
	}

	NSError *resolveError = nil;
	MADSQLStatementResolver *resolver = [[MADSQLStatementResolver alloc] initWithStatement:statement database:db];
	MADSQLQueryPlan *plan = [resolver resolveWithError:&resolveError];
	if (plan == nil) {
		_sqlStatusLabel.textColor = [NSColor systemRedColor];
		_sqlStatusLabel.stringValue = [NSString stringWithFormat:@"SQL Resolve Error: %@", resolveError.localizedDescription];
		return;
	}

	NSError *applyError = nil;
	MADSQLQueryCompiler *compiler = [[MADSQLQueryCompiler alloc] initWithPlan:plan
																	 document:headless
																		query:query
																	  context:ctx];
	if (![compiler applyWithError:&applyError]) {
		_sqlStatusLabel.textColor = [NSColor systemRedColor];
		_sqlStatusLabel.stringValue = [NSString stringWithFormat:@"SQL Apply Error: %@", applyError.localizedDescription];
		return;
	}

	_sqlStatusLabel.textColor = [NSColor systemGreenColor];
	_sqlStatusLabel.stringValue = @"SQL compiled and applied to document query!";
	[_document notifyDocumentMutated];
}

- (void)refreshPreviewData:(id) __unused sender {
	_sqlStatusLabel.textColor = [NSColor secondaryLabelColor];
	_sqlStatusLabel.stringValue = @"Refreshing query results…";
	__weak typeof(self) weakSelf = self;
	[_document refreshDataWithPassword:nil completion:^(BOOL success, NSError * _Nullable error) {
		typeof(self) strongSelf = weakSelf;
		if (strongSelf == nil) return;
		if (success) {
			MADDataTableFast *dt = strongSelf.document.headlessDocument.dataTable;
			strongSelf.sqlStatusLabel.textColor = [NSColor systemGreenColor];
			strongSelf.sqlStatusLabel.stringValue = [NSString stringWithFormat:@"Refreshed %lu rows (%lu columns).",
													 (unsigned long)[dt numberOfRows],
													 (unsigned long)[dt numberOfColumns]];
			[strongSelf rebuildPreviewColumnsAndReload];
		} else {
			strongSelf.sqlStatusLabel.textColor = [NSColor systemRedColor];
			strongSelf.sqlStatusLabel.stringValue = error.localizedDescription ?: @"Refresh failed.";
		}
	}];
}

#pragma mark - NSTableViewDataSource & Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	if (tableView == _schemaTablesTable) return (NSInteger)_schemaTables.count;
	if (tableView == _queryTablesTable) return (NSInteger)_queryTables.count;
	if (tableView == _queryFieldsTable) return (NSInteger)_queryFields.count;
	if (tableView == _joinsTable) return (NSInteger)_queryLinks.count;
	if (tableView == _predicatesTable) return (NSInteger)_queryPredicates.count;
	if (tableView == _groupsTable) return (NSInteger)_queryGroups.count;
	if (tableView == _previewDataTable) {
		MADDataTableFast *dt = _document.headlessDocument.dataTable;
		return (NSInteger)[dt numberOfRows];
	}
	return 0;
}

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
	NSString *text = @"";
	if (tableView == _schemaTablesTable && (NSUInteger)row < _schemaTables.count) {
		RptqDatabaseSchemaTable *st = _schemaTables[(NSUInteger)row];
		text = [NSString stringWithFormat:@"%@ (%lu cols)", st.name ?: @"", (unsigned long)st.hasFields.count];
	} else if (tableView == _queryTablesTable && (NSUInteger)row < _queryTables.count) {
		RptqQueryTable *qt = _queryTables[(NSUInteger)row];
		text = [NSString stringWithFormat:@"%@ (alias: %@)", qt.databaseSchemaTable.name ?: @"", qt.alias ?: @""];
	} else if (tableView == _queryFieldsTable && (NSUInteger)row < _queryFields.count) {
		RptqQueryField *qf = _queryFields[(NSUInteger)row];
		text = [NSString stringWithFormat:@"%@.%@",
				qf.inQueryTable.alias ?: qf.inQueryTable.databaseSchemaTable.name ?: @"",
				qf.databaseSchemaField.name ?: @""];
	} else if (tableView == _joinsTable && (NSUInteger)row < _queryLinks.count) {
		RptqQueryLinks *link = _queryLinks[(NSUInteger)row];
		text = [link linkDescription] ?: @"Join";
	} else if (tableView == _predicatesTable && (NSUInteger)row < _queryPredicates.count) {
		RptqQueryPredicate *pred = _queryPredicates[(NSUInteger)row];
		text = [pred symbolForDisplay] ?: @"Predicate";
	} else if (tableView == _groupsTable && (NSUInteger)row < _queryGroups.count) {
		RptqQueryGroup *grp = _queryGroups[(NSUInteger)row];
		text = [NSString stringWithFormat:@"%ld. %@ (%@)", (long)(row + 1), [grp fieldNameNice] ?: @"", [grp sortDisplayNice] ?: @"ASC"];
	} else if (tableView == _previewDataTable) {
		MADDataTableFast *dt = _document.headlessDocument.dataTable;
		NSDictionary *rowDict = [dt dataForRow:(NSUInteger)row error:NULL];
		id val = tableColumn.identifier ? rowDict[tableColumn.identifier] : nil;
		if (val != nil && val != [NSNull null]) {
			text = [val description];
		}
	}

	NSTextField *cell = [tableView makeViewWithIdentifier:@"Cell" owner:self];
	if (cell == nil) {
		cell = [NSTextField labelWithString:text];
		cell.identifier = @"Cell";
		cell.lineBreakMode = NSLineBreakByTruncatingTail;
		cell.font = [NSFont systemFontOfSize:12.0];
	} else {
		cell.stringValue = text;
	}
	return cell;
}

@end
