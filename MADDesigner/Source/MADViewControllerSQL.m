//
//  MUIViewControllerShowSql.m
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADViewControllerSQL.h"

#import <MADCocoaExtensions/MADAlertController.h>
#import <MADAPI/MADViewControllerStandardProtocol.h>
#import <MADAPI/MADQuery.h>
#import <MADAPI/MADDatabase.h>

#import <MAD/MADocument.h>
#import <MAD/MADQueryFull.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/MADSQLCompileError.h>
#import <MAD/MADSQLParser.h>
#import <MAD/MADSQLStatement.h>
#import <MAD/MADSQLStatementResolver.h>
#import <MAD/MADSQLQueryCompiler.h>

#import "MADOperationValidateSQL.h"

#import <UIKit/UIKit.h>
#import <UIKit/UITextView.h>
#import <UIKit/UISegmentedControl.h>
#import <UIKit/UIButton.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIStackView.h>
#import <UIKit/UIAlertController.h>
#import <UIKit/UIFont.h>

static const CGFloat MADSQLStatusHeight = 28.0;

@implementation MADViewControllerSQL

#pragma mark - Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];

	// The storyboard's scene is the read-only text view alone; the SQL entry
	// modes are built here, in code, so the storyboard stays untouched.
	UITextView *viewTextView = self.textView;
	[viewTextView removeFromSuperview];
	NSMutableArray<NSLayoutConstraint *> *orphaned = [NSMutableArray array];
	for (NSLayoutConstraint *constraint in self.view.constraints) {
		if (constraint.firstItem == viewTextView || constraint.secondItem == viewTextView) {
			[orphaned addObject:constraint];
		}
	}
	[self.view removeConstraints:orphaned];
	viewTextView.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];

	self.modeControl = [[UISegmentedControl alloc] initWithItems:@[ NSLocalizedString(@"View", @"View"), NSLocalizedString(@"Edit", @"Edit") ]];
	self.modeControl.selectedSegmentIndex = 0;
	[self.modeControl addTarget:self action:@selector(modeChanged:) forControlEvents:UIControlEventValueChanged];
	self.navigationItem.titleView = self.modeControl;

	self.tabControl = [[UISegmentedControl alloc] initWithItems:@[ NSLocalizedString(@"Generated", @"Generated"), NSLocalizedString(@"As entered", @"As entered") ]];
	self.tabControl.selectedSegmentIndex = 0;
	[self.tabControl addTarget:self action:@selector(tabChanged:) forControlEvents:UIControlEventValueChanged];

	self.editTextView = [[UITextView alloc] initWithFrame:CGRectZero];
	self.editTextView.translatesAutoresizingMaskIntoConstraints = NO;
	self.editTextView.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
	self.editTextView.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.editTextView.autocorrectionType = UITextAutocorrectionTypeNo;
	self.editTextView.keyboardType = UIKeyboardTypeASCIICapable;
	self.editTextView.hidden = YES;

	self.revertButton = [UIButton buttonWithType:UIButtonTypeSystem];
	[self.revertButton setTitle:NSLocalizedString(@"Revert to generated", @"Revert to generated") forState:UIControlStateNormal];
	[self.revertButton addTarget:self action:@selector(revertToGenerated:) forControlEvents:UIControlEventTouchUpInside];

	self.validateButton = [UIButton buttonWithType:UIButtonTypeSystem];
	[self.validateButton setTitle:NSLocalizedString(@"Validate", @"Validate") forState:UIControlStateNormal];
	[self.validateButton addTarget:self action:@selector(validate:) forControlEvents:UIControlEventTouchUpInside];

	self.applyButton = [UIButton buttonWithType:UIButtonTypeSystem];
	[self.applyButton setTitle:NSLocalizedString(@"Apply", @"Apply") forState:UIControlStateNormal];
	[self.applyButton addTarget:self action:@selector(apply:) forControlEvents:UIControlEventTouchUpInside];

	self.buttonsRow = [[UIStackView alloc] initWithArrangedSubviews:@[ self.revertButton, self.validateButton, self.applyButton ]];
	self.buttonsRow.axis = UILayoutConstraintAxisHorizontal;
	self.buttonsRow.distribution = UIStackViewDistributionFillEqually;
	self.buttonsRow.hidden = YES;

	self.statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	self.statusLabel.font = [UIFont systemFontOfSize:12];
	self.statusLabel.numberOfLines = 0;
	self.statusLabel.text = @"";

	UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[ self.tabControl, viewTextView, self.editTextView, self.buttonsRow, self.statusLabel ]];
	stack.axis = UILayoutConstraintAxisVertical;
	stack.spacing = 8.0;
	stack.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:stack];
	[NSLayoutConstraint activateConstraints:@[
		[stack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8.0],
		[stack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:8.0],
		[stack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-8.0],
		[stack.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-8.0],
		[self.buttonsRow.heightAnchor constraintEqualToConstant:MADSQLStatusHeight],
	]];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	// The As entered tab exists only when the query was built from pasted SQL.
	NSString *sourceText = [self enteredText];
	if (sourceText.length == 0) {
		self.tabControl.hidden = YES;
	} else {
		self.tabControl.hidden = NO;
	}

	self.modeControl.selectedSegmentIndex = 0;
	[self updateForMode];
}

#pragma mark - The two representations

- (NSString *)generatedSQL {
	MADocument *doc = self.document;
	NSError *error = nil;
	NSString *sql = [doc.mainQuery SQLOnlyActiveFields:NO managedObjectContext:doc.storeContext error:&error];
	if (error != nil) sql = error.localizedDescription;
	return sql != nil ? sql : @"";
}

- (NSString *)enteredText {
	MADocument *doc = self.document;
	NSString *sourceText = doc.activeDocumentModel.mainQuery.sqlSourceText;
	return sourceText != nil ? sourceText : @"";
}

- (void)updateForMode {
	BOOL editing = self.modeControl.selectedSegmentIndex == 1;
	self.tabControl.hidden = editing || [self enteredText].length == 0;
	self.textView.hidden = editing;
	self.editTextView.hidden = !editing;
	self.buttonsRow.hidden = !editing;
	self.statusLabel.text = @"";

	if (editing) {
		// Edit seeds from the user's own words when they exist -- formatting
		// and comments intact -- and from the generated form otherwise.
		NSString *sourceText = [self enteredText];
		self.editTextView.text = sourceText.length > 0 ? sourceText : [self generatedSQL];
	} else {
		[self updateViewTab];
	}
}

- (void)updateViewTab {
	if (self.tabControl.selectedSegmentIndex == 1) {
		self.textView.text = [self enteredText];
	} else {
		NSString *sql = [self generatedSQL];
		if (sql.length > 0) {
			self.textView.text = sql;
		} else {
			self.textView.text = @"";
			[self presentViewController:[MADViewControllerSQL alertErrorEmptyQuery] animated:YES completion:nil];
		}
	}
	self.textView.textColor = [UIColor labelColor];
}

#pragma mark - Actions

- (void)modeChanged:(UISegmentedControl *)sender {
	[self updateForMode];
}

- (void)tabChanged:(UISegmentedControl *)sender {
	[self updateViewTab];
}

- (void)revertToGenerated:(id)sender {
	self.editTextView.text = [self generatedSQL];
}

- (IBAction)done:(id)sender {
	[self.delegate viewControllerDidFinish:self];
}

#pragma mark - The schema the importer validates against

- (NSDictionary<NSString *, NSArray<NSString *> *> *)schemaDictionary {
	MADocument *document = self.document;
	NSMutableDictionary<NSString *, NSArray<NSString *> *> *schema = [NSMutableDictionary dictionary];
	for (RptqDatabaseSchemaTable *table in document.activeDocumentModel.defaultDatabase.hasTables) {
		NSString *tableName = table.name;
		if (tableName == nil) continue;
		NSMutableArray<NSString *> *names = [NSMutableArray arrayWithCapacity:table.hasFields.count];
		for (RptqDatabaseSchemaField *field in table.hasFields) {
			NSString *fieldName = field.name;
			if (fieldName != nil) {
				[names addObject:fieldName];
			}
		}
		schema[tableName] = names;
	}
	return schema;
}

// The resolved select columns, for the probe's mismatch comparison: lowercase
// bare name -> the schema field's data type.
- (NSDictionary<NSString *, NSNumber *> *)expectedColumnsForStatement:(MADSQLStatement *)statement {
	MADocument *document = self.document;
	RptqDatabase *database = document.activeDocumentModel.defaultDatabase;
	NSMutableDictionary<NSString *, NSNumber *> *expected = [NSMutableDictionary dictionary];

	for (MADSQLColumnReference *column in statement.selectColumns) {
		if (column.isWildcard) {
			NSString *columnTable = column.table.lowercaseString;
			if (columnTable == nil) continue;
			for (RptqDatabaseSchemaTable *table in database.hasTables) {
				if (![table.name.lowercaseString isEqualToString:columnTable]) continue;
				for (RptqDatabaseSchemaField *field in table.hasFields) {
					NSString *lowerName = field.name.lowercaseString;
					if (lowerName != nil) {
						expected[lowerName] = @(field.dataType);
					}
				}
			}
			continue;
		}
		for (RptqDatabaseSchemaTable *table in database.hasTables) {
			for (RptqDatabaseSchemaField *field in table.hasFields) {
				NSString *lowerName = field.name.lowercaseString;
				if (lowerName == nil || ![lowerName isEqualToString:column.name.lowercaseString]) continue;
				expected[lowerName] = @(field.dataType);
			}
		}
	}
	return expected;
}

#pragma mark - Validate

- (void)validate:(id)sender {
	NSString *sql = self.editTextView.text;
	MADocument *document = self.document;

	// Structural: parse and resolve, offline, always.
	MADSQLParser *parser = [[MADSQLParser alloc] initWithSQL:sql
									 identifierQuoteCharacters:[MADDatabase identifierQuoteCharacters]
													   schema:[self schemaDictionary]];
	NSError *error = nil;
	MADSQLStatement *statement = [parser parseStatement:&error];
	if (statement == nil) {
		[self presentCompileError:error];
		return;
	}
	MADSQLStatementResolver *resolver = [[MADSQLStatementResolver alloc] initWithStatement:statement
																				  database:document.activeDocumentModel.defaultDatabase];
	MADSQLQueryPlan *plan = [resolver resolveWithError:&error];
	if (plan == nil) {
		[self presentCompileError:error];
		return;
	}

	self.statusLabel.text = NSLocalizedString(@"Validating…", @"Validating…");

	// The server probe, when the database can be reached; advisory.
	MADOperationValidateSQL *probe = [[MADOperationValidateSQL alloc] initWithDocument:document
																			 statement:sql
																	 expectedColumns:[self expectedColumnsForStatement:statement]];
	__weak MADViewControllerSQL *weakSelf = self;
	NSBlockOperation *completion = [NSBlockOperation blockOperationWithBlock:^{
		dispatch_async(dispatch_get_main_queue(), ^{
			[weakSelf probeFinished:probe];
		});
	}];
	[completion addDependency:probe];
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	[queue addOperations:@[ probe, completion ] waitUntilFinished:NO];
}

- (void)probeFinished:(MADOperationValidateSQL *)probe {
	if (probe.skipped) {
		self.statusLabel.text = NSLocalizedString(@"Validated by structure only.", @"Validated by structure only.");
		return;
	}
	if (probe.errors.count > 0) {
		NSError *error = probe.errors.firstObject;
		[self presentCompileError:error];
		return;
	}
	if (probe.warnings.count > 0) {
		self.statusLabel.text = [probe.warnings componentsJoinedByString:@"\n"];
		return;
	}
	self.statusLabel.text = NSLocalizedString(@"The server validated the statement.", @"The server validated the statement.");
}

#pragma mark - Apply

- (void)apply:(id)sender {
	NSString *sql = self.editTextView.text;
	MADocument *doc = self.document;

	MADSQLParser *parser = [[MADSQLParser alloc] initWithSQL:sql
									 identifierQuoteCharacters:[MADDatabase identifierQuoteCharacters]
													   schema:[self schemaDictionary]];
	NSError *error = nil;
	MADSQLStatement *statement = [parser parseStatement:&error];
	if (statement == nil) {
		[self presentCompileError:error];
		return;
	}
	MADSQLStatementResolver *resolver = [[MADSQLStatementResolver alloc] initWithStatement:statement
																				  database:doc.activeDocumentModel.defaultDatabase];
	MADSQLQueryPlan *plan = [resolver resolveWithError:&error];
	if (plan == nil) {
		[self presentCompileError:error];
		return;
	}
	MADSQLQueryCompiler *compiler = [[MADSQLQueryCompiler alloc] initWithPlan:plan
																	 document:doc
																		query:doc.activeDocumentModel.mainQuery
																	  context:doc.storeContext];
	if (![compiler applyWithError:&error]) {
		[self presentCompileError:error];
		return;
	}

	// The apply is the document's new state: mark it dirty and autosave, the
	// way the add-table flow does; the query UI and the visualization update
	// through the store's own notifications.
	self.statusLabel.text = [[NSString alloc] initWithFormat:
		NSLocalizedString(@"Applied: %lu table(s), %lu join(s), %lu predicate(s), %lu group(s).", @"Applied: %lu table(s), %lu join(s), %lu predicate(s), %lu group(s)."),
		(unsigned long)plan.tables.count, (unsigned long)plan.links.count,
		(unsigned long)plan.predicates.count, (unsigned long)plan.groups.count];
	[doc updateChangeCount:UIDocumentChangeDone];
	[doc autosaveWithCompletionHandler:^(BOOL __unused success) { }];
}

// A coded error, shown with its code, message and position.
- (void)presentCompileError:(NSError *)error {
	NSString *message = error.localizedDescription;
	NSNumber *line = error.userInfo[MADSQLCompileErrorLineKey];
	NSNumber *column = error.userInfo[MADSQLCompileErrorColumnKey];
	if (line != nil && column != nil) {
		message = [[NSString alloc] initWithFormat:@"%@ (line %@, column %@)", message, line, column];
	}
	NSString *title = [[NSString alloc] initWithFormat:@"%@ (%ld)", NSLocalizedString(@"The statement was rejected", @"The statement was rejected"), (long)error.code];
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
																   message:message
															preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Continue", @"Continue") style:UIAlertActionStyleDefault handler:nil]];
	[self presentViewController:alert animated:YES completion:nil];
	self.statusLabel.text = @"";
}

#pragma mark - The empty query

+ (UIAlertController *)alertErrorEmptyQuery {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Empty Query", @"Empty Query")
																   message: NSLocalizedString(@"Add tables to the query and data fields to the designer to generate a query.", @"Add tables to the query and data fields to the designer to generate a query.")
															preferredStyle: UIAlertControllerStyleAlert];
	UIAlertAction *ok = [UIAlertAction actionWithTitle: NSLocalizedString(@"Continue", @"Continue")
												 style: UIAlertActionStyleDefault
											   handler: nil];
	[alert addAction: ok];
	return alert;
}

@end
