//
//  MADQueryViewControllerLayout.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/6/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADQueryViewDataSource.h"
#import "MADTableViewCellQueryTableName.h"
#import "MADTableViewCellQueryLink.h"
#import "MADTableViewCellQueryPredicate.h"
#import "MADTableViewCellQueryGroup.h"

#import "MADQueryViewSectionDelegate.h"
#import "MADQueryViewDatasourceProtocol.h"
#import <MADFoundation/madlog.h>

#import <MAD/MADocument.h>
#import <MAD/RptqStoreContext.h>

#import <MAD/RptqDatabaseCredentals.h>
#import <MAD/RptqDatabaseCredentals+Extras.h>

#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqQuery+Extras.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqQueryGroup+Extras.h>
#import <MAD/RptqQueryLinks+Extras.h>
#import <MAD/RptqQueryPredicate+Extras.h>
#import <MAD/RptqQueryTable+Extras.h>

#import <MAD/MADModelDocument.h>
#import <MAD/MADModelDatabase.h>
#import <MAD/MADModelQuery.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import <MADFoundation/MADStringUtilities.h>
#import <MADFoundation/MADStringUtilities.h>

#import <Foundation/NSIndexPath.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSOrderedSet.h>


#import <UIKit/UILabel.h>
#import <UIKit/UIFont.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/NSParagraphStyle.h>


short numberOfSectionsForQueryTableCount(NSUInteger, BOOL);
short numberOfSectionsForQueryTableCount(NSUInteger queryTableCount, BOOL reportingEnabled) {
	switch (queryTableCount) {
		case 0:
			return reportingEnabled ? 3 : 2;
			break;
		case 1:
			return reportingEnabled ? 5 : 4;
			break;
		default:
			return reportingEnabled ? 6 : 5;
			break;
	}
}

@interface MADQueryViewDataSource ()

	@property (readwrite, nonatomic, assign) short count;

	@property (readwrite, nonatomic, weak) RptqStoreContext *managedObjectContext;
	@property (readwrite, nonatomic, strong) NSArray <MADQueryViewSectionDelegate *> *sections;

	@property (readwrite, nonatomic, weak) MADQueryViewCellConfigureHandler handleConfigureCell;

	@property (readwrite, nonatomic, strong) NSArray *queryTablesController;
	@property (readwrite, nonatomic, strong) NSArray *queryLinksController;
	@property (readwrite, nonatomic, strong) NSArray *queryGroupsController;
	@property (readwrite, nonatomic, strong) NSArray *queryPredicatesController;

@end

@implementation MADQueryViewDataSource {
	BOOL _reportingEnabled;
	NSUInteger _numberOfTables;
	int64_t _queryID;
}

- (void)dealloc {
	_managedObjectContext = nil;
	//_sections = nil;
	_handleConfigureCell = nil;
	//_datasoruce = nil;
	//if (_queryLinksController) {
	//    _queryLinksController.delegate = nil;
//        _queryLinksController = nil;
	//}
	//if (_queryTablesController) {
	//    _queryTablesController.delegate = nil;
//        _queryTablesController = nil;
	//}
	//if (_queryGroupsController) {
	//    _queryGroupsController.delegate = nil;
//        _queryGroupsController = nil;
	//}
	//if (_queryPredicatesController) {
	//    _queryPredicatesController.delegate = nil;
//        _queryPredicatesController = nil;
	//}
}

- (instancetype)initWithQueryID: (NSNumber *)queryID
		   managedObjectContext: (RptqStoreContext *)managedObjectContext
			   reportingEnabled: (BOOL)reportingEnabled
			handleConfigureCell: (MADQueryViewCellConfigureHandler)handleConfigureCell {
	if (self = [super init]) {

		_queryID = queryID.longLongValue;

		NSArray *tables = [managedObjectContext objectsForEntity:NSStringFromClass([RptqQueryTable class])];
		NSUInteger numberOfTables = 0;
		for (RptqQueryTable *table in tables) {
			if (table.inQuery.identifier == queryID.longLongValue) numberOfTables++;
		}

		_count = numberOfSectionsForQueryTableCount(numberOfTables, reportingEnabled);
		_reportingEnabled = reportingEnabled;
		_numberOfTables = (unsigned long)numberOfTables;
		_handleConfigureCell = handleConfigureCell;
		_managedObjectContext = managedObjectContext;

	}
	return self;
}

- (instancetype)initWithNumberOfTables:(NSUInteger)numberOfTables
					  reportingEnabled:(BOOL)reportingEnabled
				   handleConfigureCell:(MADQueryViewCellConfigureHandler)handleConfigureCell {

	if (self = [super init]) {
		
		_count = numberOfSectionsForQueryTableCount(numberOfTables, reportingEnabled);
		_reportingEnabled = reportingEnabled;
		_numberOfTables = numberOfTables;
		_handleConfigureCell = handleConfigureCell;

	}
	return self;
}

- (void)numberOfTablesChanged:(NSUInteger)numberOfTables {
	_count = numberOfSectionsForQueryTableCount(numberOfTables, _reportingEnabled);
	_numberOfTables = numberOfTables;
	_sections = nil;
}

- (MADIdentifierQueryViewSections)sectionAtIndex:(short)index {
	MADQueryViewSectionDelegate *layout;
	layout = [[MADQueryViewSectionDelegate alloc] initWithNumberOfTables: _numberOfTables
																position: index];
	return layout.querySection;
}

- (NSIndexSet *)sectionTypesIndexs {
	NSMutableIndexSet *sectionTypes = [[NSMutableIndexSet alloc] init];
	NSArray <__kindof MADQueryViewSectionDelegate *> *sections = self.sections;
	for (MADQueryViewSectionDelegate *section in sections) {
		[sectionTypes addIndex:(unsigned int)section.querySection];
	}
	return sectionTypes;
}

- (NSSet <__kindof NSNumber *> *)sectionTypes {
	NSMutableSet <__kindof NSNumber *> *sectionTypes;
	sectionTypes = [[NSMutableSet alloc] initWithCapacity:(NSUInteger)_count];
	for (MADQueryViewSectionDelegate *section in self.sections) {
		NSNumber *sectionType = [[NSNumber alloc] initWithShort:section.querySection];
		[sectionTypes addObject:sectionType];
	}
	return sectionTypes;
}

- (MADQueryViewSectionDelegate *)layoutAtIndex:(short)index {
	return self.sections[(NSUInteger)index];
}

- (NSArray <__kindof MADQueryViewSectionDelegate *> *)sections {
	if (_sections != nil) {
		return _sections;
	} else {
	
		NSMutableArray <__kindof MADQueryViewSectionDelegate *> *sections = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)_count];
		for (short i = 0; i < _count; i++) {
			MADQueryViewSectionDelegate *section = [[MADQueryViewSectionDelegate alloc] initWithNumberOfTables: _numberOfTables
																									  position: i];
			[sections addObject:section];
		}
		_sections = sections;
		return _sections;
	}
}

- (NSInteger)numberOfRowsInSection:(MADIdentifierQueryViewSections)section {
	switch (section) {

		case MADIdentifierQueryViewSectionsTables:
			return (NSInteger)_queryTablesController.count;
			break;

		case MADIdentifierQueryViewSectionsLinks:
			return (NSInteger)_queryLinksController.count;
			break;

		case MADIdentifierQueryViewSectionsPredicate:
			return (NSInteger)_queryPredicatesController.count;
			break;

		case MADIdentifierQueryViewSectionsGroups:
			return (NSInteger)_queryGroupsController.count;
			break;

		default:
			return 0;
			break;
	}
}

- (BOOL)canEditSectionAtIndex:(short)index {
	MADIdentifierQueryViewSections sectionType = [self sectionAtIndex:index];
	return (sectionType == MADIdentifierQueryViewSectionsTables ||
			sectionType == MADIdentifierQueryViewSectionsGroups ||
			sectionType == MADIdentifierQueryViewSectionsPredicate ||
			sectionType == MADIdentifierQueryViewSectionsLinks);
}

#pragma mark -
#pragma mark Fetching

- (void)performFetchAll {
	[self performFetchTables];
	[self performFetchLinks];
	[self performFetchGroups];
	[self performFetchPredicate];
}

- (void)performFetchTables {
	_queryTablesController = nil;
	(void)self.queryTablesController;
}

- (void)performFetchLinks {
	_queryLinksController = nil;
	(void)self.queryLinksController;
}

- (void)performFetchGroups {
	_queryGroupsController = nil;
	(void)self.queryGroupsController;
}

- (void)performFetchPredicate {
	_queryPredicatesController = nil;
	(void)self.queryPredicatesController;
}

#pragma mark -
#pragma mark Table View Data Source Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return (NSInteger)_count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	MADQueryViewSectionDelegate *layoutSection = [self layoutAtIndex:(short)section];
	NSInteger numberOfRows = layoutSection.numberOfRows == NSNotFound ? [self numberOfRowsInSection:layoutSection.querySection] : 1;
	return numberOfRows;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return [self canEditSectionAtIndex:(short)indexPath.section];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return ([self sectionAtIndex:(short)indexPath.section] == MADIdentifierQueryViewSectionsGroups);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style
											forRowAtIndexPath:(NSIndexPath *)indexPath {
	id <MADQueryViewControllerDatasourceProtocol> datasoruce = self.datasoruce;
	switch (style) {
			
		case UITableViewCellEditingStyleDelete:
			[datasoruce queryDatasource: datasoruce
							  tableView: tableView
							 deleteItem: indexPath
							fromSection: [self sectionAtIndex:(short)indexPath.section]];
			break;
			
		case UITableViewCellEditingStyleInsert:
			break;
			
		case UITableViewCellEditingStyleNone:
			break;
			
		default:
			break;
	}
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
	  toIndexPath:(NSIndexPath *)toIndexPath {

	switch ([self sectionAtIndex:(short)toIndexPath.section]) {
		case MADIdentifierQueryViewSectionsGroups: {
			
			NSIndexPath *fromIndex = [NSIndexPath indexPathForRow: fromIndexPath.row inSection: 0];
			NSIndexPath *toIndex = [NSIndexPath indexPathForRow: toIndexPath.row inSection: 0];

			RptqQueryGroup *fromGroup = _queryGroupsController[(NSUInteger)fromIndex.row];
			RptqQueryGroup *toGroup =   _queryGroupsController[(NSUInteger)toIndex.row];
			
			fromGroup.weight = toGroup.weight;
			toGroup.weight = fromGroup.weight;

			MADocument *document = self.datasoruce.document;
			
			NSError *error = nil;
			BOOL saved = [self.managedObjectContext save:&error];
			if (!saved && error != nil) {
				os_log_error(GetDesignerLog(), "%s Error fetching: %@", __PRETTY_FUNCTION__, error);
			}
			[document updateChangeCount: UIDocumentChangeDone];

			[self performFetchGroups];
			break;
		}
		default:
			break;
	}
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
		 cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	UITableViewCell *cell = nil;
	
	NSInteger row = indexPath.row;
	MADIdentifierQueryViewSections section = [self sectionAtIndex:(short)indexPath.section];
	
	switch (section) {
			
		// MARK: Display and identify the data source and data sources
		case MADIdentifierQueryViewSectionsDatasource: {
			
			static NSString *MADIdentifierCellDataSource = @"MADIdentifierDataSource";
			cell = [tableView dequeueReusableCellWithIdentifier: MADIdentifierCellDataSource];
			
			MADocument *madDocument = self.datasoruce.document;
			MADModelDatabase *db = madDocument.documentModel.firstDatabase;
			if (!db) {
				os_log_error(GetDesignerLog(), "%s: Missing database.", __PRETTY_FUNCTION__);
				break;
			}
			NSString *databaseType = db.driverID.copy;
			NSString *schemaName = db.schemaName.copy;
			
			NSString *localizedMessage = [[NSString alloc] initWithFormat:NSLocalizedString(@"You are connecting to %1$@ datasource named %2$@.", @"You are connecting to %1$@ datasource named %2$@."), databaseType, schemaName];
			NSAttributedString *message = [MADQueryViewDataSource attributedStringForQuerySectionDatasourceWithMessage: localizedMessage
																										  databaseType: databaseType
																											schemaName: schemaName];
			cell.textLabel.attributedText = message;
			cell.textLabel.text = localizedMessage;
			break;
		}
			
			// MARK: Display the table names that are used in the query
		case MADIdentifierQueryViewSectionsTables: {
			
			static NSString *MyIdentifierUITableViewCellTableName = @"MADIdentifierCellSchemaName";
			cell = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellTableName];
			
			NSIndexPath *path = [NSIndexPath indexPathForRow: row inSection: 0];
			RptqQueryTable *tablea = self.queryTablesController[(NSUInteger)path.row];
			cell.textLabel.text = tablea.alias.copy;

			break;

		}
			
			// MARK: Display the table links or joins that are used in the query.
		case MADIdentifierQueryViewSectionsLinks: {
			
			static NSString *MADIDCellInstruction = @"MADIdentifierCellQueryLink";
			cell = [tableView dequeueReusableCellWithIdentifier: MADIDCellInstruction];
			
			NSIndexPath *indexPathLinks = [NSIndexPath indexPathForRow: row inSection: 0];
			RptqQueryLinks *links = self.queryLinksController[(NSUInteger)indexPathLinks.row];
			
			NSString *leftString = [MADQueryViewDataSource stringForFieldDisplayWithTable: links.tableLeftID
																				 andField: links.fieldLeftID];
			
			NSString *rightString = [MADQueryViewDataSource stringForFieldDisplayWithTable: links.tableRightID
																				  andField: links.fieldRightID];

			NSAttributedString *message = [MADQueryViewDataSource attributedStringForQuerySectionLinksWithLeftString: leftString
																										 rightString: rightString
																									linksDescription: [links linkDescription]];
			((MADTableViewCellQueryLink *)cell).linkID = links.identifier;
			cell.textLabel.attributedText = message;

			break;
		}
			
			// MARK: Display the groupings used in the query.
		case MADIdentifierQueryViewSectionsGroups: {
			
			static NSString *MADIDCellInstruction = @"MADIdentifierQueryGroup";
			cell = [tableView dequeueReusableCellWithIdentifier: MADIDCellInstruction];
			
			
			NSIndexPath *path = [NSIndexPath indexPathForRow: row inSection: 0];
			RptqQueryGroup *group = self.queryGroupsController[(NSUInteger)path.row];
			cell.backgroundView.backgroundColor = [UIColor whiteColor];
			
			NSString *field = [[group fieldNameNice] copy];
			NSString *sort  = [[group sortDisplayNice] copy];
			NSAttributedString *message = [MADQueryViewDataSource attributedStringForQuerySectionGroupWithField: field
																										andSort: sort];
			cell.textLabel.attributedText = message;
			((MADTableViewCellQueryGroup *)cell).groupID = group.identifier;

			break;
		}
			
		// MARK: Display the predicates or conditions on the query.
		case MADIdentifierQueryViewSectionsPredicate: {
			static NSString *MADIDCellPredicate = @"MADIdentifierQueryPredicate";
			cell = [tableView dequeueReusableCellWithIdentifier: MADIDCellPredicate];
			RptqQueryPredicate *predicate = self.queryPredicatesController[(NSUInteger)row];
			NSString *symbol = [predicate symbolForDisplay];
			NSString *leftFieldDisplay = predicate.leftFieldID ?: [predicate.hasLeftField toString];
			NSString *rightFieldDisplay = predicate.rightFieldID ?: [predicate.hasRightField toString];
			NSAttributedString *message = [MADQueryViewDataSource attributedStringForQueryPredicateWithLeftText: leftFieldDisplay
																										 symbol: symbol
																									  rightText: rightFieldDisplay];
			((MADTableViewCellQueryPredicate *)cell).predicateID = predicate.identifier;
			cell.textLabel.attributedText = message;
			break;
		}
			
		case MADIdentifierQueryViewSectionsSql: {
			switch (row) {
				case 0: {
					static NSString *MADIDCellOverride = @"UITableViewCellOverride";
					cell = [tableView dequeueReusableCellWithIdentifier: MADIDCellOverride];
					break;
				}
				default: {
					static NSString *MADIDCellQueryInput = @"MADIdentifierQueryInput";
					cell = [tableView dequeueReusableCellWithIdentifier: MADIDCellQueryInput];
					break;
				}
			}
			break;
		}
			
		case MADIdentifierQueryViewSectionsNumberOfQueryResults: {
			static NSString *idNumberOfQueryResults = @"MADIdentifierQueryCountID";
			cell = [tableView dequeueReusableCellWithIdentifier: idNumberOfQueryResults];
			break;
		}
			
		default: {
			break;
		}
			
	}
	
	if (cell) {
		self.handleConfigureCell(cell, section, indexPath.row);
	} else {
		static NSString *idDefaultCell = @"DefaultCellShouldNotGetHere";
		cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault
									  reuseIdentifier: idDefaultCell];
	}
	
	return cell;
}

#pragma mark -
#pragma mark Overrides

- (NSArray *)queryLinksController {
	if (_queryLinksController == nil) {
		RptqStoreContext *context = self.datasoruce.document.storeContext;
		NSArray *links = [context objectsForEntity:NSStringFromClass([RptqQueryLinks class])];
		links = [links filteredArrayUsingPredicate:
				 [NSPredicate predicateWithFormat:@"hasLeftField.inQueryTable.inQuery.identifier == %lld", _queryID]];
		links = [links sortedArrayUsingComparator:^NSComparisonResult(RptqQueryLinks *a, RptqQueryLinks *b) {
			return [(a.tableLeftID ?: @"") compare:(b.tableLeftID ?: @"")];
		}];
		_queryLinksController = links;
	}
	return _queryLinksController;
}

- (NSArray *)queryGroupsController {
	if (_queryGroupsController == nil) {
		RptqStoreContext *context = self.datasoruce.document.storeContext;
		NSArray *groups = [context objectsForEntity:NSStringFromClass([RptqQueryGroup class])];
		groups = [groups filteredArrayUsingPredicate:
				  [NSPredicate predicateWithFormat:@"inQuery.identifier == %lld", _queryID]];
		groups = [groups sortedArrayUsingComparator:^NSComparisonResult(RptqQueryGroup *a, RptqQueryGroup *b) {
			if (a.weight < b.weight) return NSOrderedAscending;
			if (a.weight > b.weight) return NSOrderedDescending;
			return NSOrderedSame;
		}];
		_queryGroupsController = groups;
	}
	return _queryGroupsController;
}

- (NSArray *)queryTablesController {
	id <MADQueryViewControllerDatasourceProtocol> datasoruce = self.datasoruce;
	if (_queryTablesController == nil) {
		RptqStoreContext *context = datasoruce.document.storeContext;
		MADModelQuery *query = datasoruce.document.documentModel.firstQuery;
		NSArray *tables = [context objectsForEntity:NSStringFromClass([RptqQueryTable class])];
		NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:tables.count];
		for (RptqQueryTable *table in tables) {
			if (table.inQuery.identifier != query.identifier) continue;
			[filtered addObject:table];
		}
		[filtered sortUsingComparator:^NSComparisonResult(RptqQueryTable *a, RptqQueryTable *b) {
			return [(a.alias ?: @"") compare:(b.alias ?: @"")];
		}];
		_queryTablesController = filtered;
	}
	return _queryTablesController;
}

- (NSArray *)queryPredicatesController {
	if (_queryPredicatesController == nil) {
		RptqStoreContext *context = self.datasoruce.document.storeContext;
		NSArray *predicates = [context objectsForEntity:NSStringFromClass([RptqQueryPredicate class])];
		predicates = [predicates filteredArrayUsingPredicate:
					  [NSPredicate predicateWithFormat:@"inQuery.identifier == %lld", _queryID]];
		predicates = [predicates sortedArrayUsingComparator:^NSComparisonResult(RptqQueryPredicate *a, RptqQueryPredicate *b) {
			return [(a.leftFieldID ?: @"") compare:(b.leftFieldID ?: @"")];
		}];
		_queryPredicatesController = predicates;
	}
	return _queryPredicatesController;
}

#pragma mark - Static Functions

+ (NSAttributedString *)attributedStringForQueryPredicateWithLeftText:(NSString *)leftText
															   symbol:(NSString *)symbol
															rightText:(NSString *)rightText {
	UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
	NSString *messageText = [[NSString alloc] initWithFormat:@"%1$@ %2$@ %3$@", leftText, symbol, rightText];
	
	NSDictionary *attributes = @{ NSFontAttributeName: font };
	UIColor *color = [MADColorEverydayApps newColorBlue];
	NSDictionary *attributesCaption = @{ NSForegroundColorAttributeName: color };
	
	NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:messageText attributes:attributes];
	NSRange rangeMiddle = [messageText rangeOfString:symbol];
	[message addAttributes:attributesCaption range:rangeMiddle];
	
	return message;
}

+ (NSAttributedString *)attributedStringForQuerySectionGroupWithField:(NSString *)field
															  andSort:(NSString *)sort {
	field = field ?: @"";
	sort = sort ?: @"";
	
	UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
	UIFont *fontCaption = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
	
	NSMutableParagraphStyle *paragraphStyleLeft = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	paragraphStyleLeft.alignment = NSTextAlignmentLeft;
	
	NSMutableParagraphStyle *paragraphStyleRight = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	paragraphStyleRight.alignment = NSTextAlignmentRight;
	
	NSString *messageText = [NSString stringWithFormat:@"%@ %@", field, sort];
	NSDictionary *attributes = @{ NSFontAttributeName: font };
	
	NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:messageText attributes:attributes];
	
	NSDictionary *attributesLeft = @{ NSParagraphStyleAttributeName: paragraphStyleLeft };
	UIColor *color = [MADColorEverydayApps newColorBlue];
	NSDictionary *attributesRight = @{
		NSParagraphStyleAttributeName: paragraphStyleLeft,
		NSFontAttributeName: fontCaption,
		NSForegroundColorAttributeName: color
	};
	
	[message addAttributes:attributesLeft range:[messageText rangeOfString:field]];
	[message addAttributes:attributesRight range:[messageText rangeOfString:sort]];
	
	return message;
}

+ (NSAttributedString *)attributedStringForQuerySectionLinksWithLeftString:(NSString *)leftString
															   rightString:(NSString *)rightString
														  linksDescription:(NSString *)linksDescription {
	
	UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
	UIFont *fontCaption = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
	
	NSMutableParagraphStyle *paragraph = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	paragraph.headIndent = 20.0;
	
	NSString *messageText = [NSString stringWithFormat:@"%@ %@ %@", leftString, linksDescription, rightString];
	
	NSDictionary *attributes = @{
		NSFontAttributeName: font,
		NSParagraphStyleAttributeName: paragraph
	};
	
	UIColor *color = [MADColorEverydayApps newColorBlue];
	NSDictionary *attributesAlt = @{
		NSFontAttributeName: fontCaption,
		NSForegroundColorAttributeName: color
	};
	
	NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:messageText attributes:attributes];
	NSRange rangeLinkDesc = [messageText rangeOfString:linksDescription];
	[message addAttributes:attributesAlt range:rangeLinkDesc];
	
	return message;
}

+ (NSAttributedString *)attributedStringForQuerySectionDatasourceWithMessage:(NSString *)localizedMessage
																databaseType:(NSString *)databaseType
																  schemaName:(NSString *)schemaName {
	
	NSString *text = [NSString stringWithFormat:localizedMessage, databaseType, schemaName];
	UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
	NSDictionary *attributes = @{ NSFontAttributeName: font };
	
	UIFont *fontItalic = [UIFont italicSystemFontOfSize:font.pointSize];
	NSDictionary *attributeItalic = @{ NSFontAttributeName: fontItalic };
	
	NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
	
	NSRange rangeDB = [text rangeOfString:databaseType];
	[message removeAttribute:NSFontAttributeName range:rangeDB];
	[message addAttributes:attributeItalic range:rangeDB];
	
	NSRange rangeSchema = [text rangeOfString:schemaName];
	[message removeAttribute:NSFontAttributeName range:rangeSchema];
	[message addAttributes:attributeItalic range:rangeSchema];
	
	return message;
}

+ (NSString *)stringForFieldDisplayWithTable:(NSString *)table andField:(NSString *)field {
	NSString *result = [MADStringUtilities stringByAppendingPeriod:table.capitalizedString];
	return [result stringByAppendingString:field.capitalizedString];
}

@end
