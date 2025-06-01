//
//  MADQueryViewControllerLayout.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/6/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADQueryViewDataSource.h"
#import "MADTableViewCellQueryTableName.h"
#import "MADTableViewCellQueryLink.h"
#import "MADTableViewCellQueryPredicate.h"
#import "MADTableViewCellQueryGroup.h"

#import "MADAttributedStringQueryController.h"

#import "MADQueryViewSectionDelegate.h"
#import "MADQueryViewDatasourceProtocol.h"
#import "madlog.h"

#import <MAD/MADocument.h>

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

#import <MADFoundation/MADStringUtilities.h>

#import <Foundation/NSIndexPath.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSOrderedSet.h>

#import <CoreData/NSExpressionDescription.h>
#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSFetchRequestExpression.h>
#import <CoreData/NSFetchedResultsController.h>
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSManagedObjectContext.h>

#import <UIKit/UILabel.h>

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
	<NSFetchedResultsControllerDelegate>

	@property (readwrite, nonatomic, assign) short count;

	@property (readwrite, nonatomic, weak) NSManagedObjectContext *managedObjectContext;
	@property (readwrite, nonatomic, strong) NSArray <MADQueryViewSectionDelegate *> *sections;

	@property (readwrite, nonatomic, weak) MADQueryViewCellConfigureHandler handleConfigureCell;

	@property (readwrite, nonatomic, strong) NSFetchedResultsController *queryTablesController;
	@property (readwrite, nonatomic, strong) NSFetchedResultsController *queryLinksController;
	@property (readwrite, nonatomic, strong) NSFetchedResultsController *queryGroupsController;
	@property (readwrite, nonatomic, strong) NSFetchedResultsController *queryPredicatesController;

@end

@implementation MADQueryViewDataSource {
	BOOL _reportingEnabled;
	NSUInteger _numberOfTables;
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
		   managedObjectContext: (NSManagedObjectContext *)managedObjectContext
			   reportingEnabled: (BOOL)reportingEnabled
			handleConfigureCell: (MADQueryViewCellConfigureHandler)handleConfigureCell {
	if (self = [super init]) {
	
		NSFetchRequest *request = [RptqQuery fetchRequestTableCount:queryID objectContext:managedObjectContext];
		NSUInteger numberOfTables = 0;

		NSError *error = nil;
		NSArray <NSDictionary <NSString *, NSNumber *> *> *result = [managedObjectContext executeFetchRequest:request error:&error];
		if (error != nil) {
			os_log_error(GetDesignerLog(), "%s Error fetching: %@", __PRETTY_FUNCTION__, error);
		}

		if (result.count > 0)
			numberOfTables = (NSUInteger)[result[0][@"madQTC"] integerValue];
		
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
	
		NSMutableArray <__kindof MADQueryViewSectionDelegate *> *sections;
		sections = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)_count];
		for (short i = 0; i < _count; i++) {
			MADQueryViewSectionDelegate *section;
			section = [[MADQueryViewSectionDelegate alloc] initWithNumberOfTables: _numberOfTables
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
			return (NSInteger)_queryTablesController.sections[0].numberOfObjects;
			break;

		case MADIdentifierQueryViewSectionsLinks:
			return (NSInteger)_queryLinksController.sections[0].numberOfObjects;
			break;

		case MADIdentifierQueryViewSectionsPredicate:
			return (NSInteger)_queryPredicatesController.sections[0].numberOfObjects;
			break;

		case MADIdentifierQueryViewSectionsGroups:
			return (NSInteger)_queryGroupsController.sections[0].numberOfObjects;
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
	NSError *error = nil;
	[self.queryTablesController performFetch:&error];
	NSAssert(error == nil, @"Error: %@", error);
}

- (void)performFetchLinks {
	NSError *error = nil;
	[self.queryLinksController performFetch:&error];
	NSAssert(error == nil, @"Error: %@", error);
}

- (void)performFetchGroups {
	NSError *error = nil;
	[self.queryGroupsController performFetch:&error];
	NSAssert(error == nil, @"Error: %@", error);
}

- (void)performFetchPredicate {
	NSError *error = nil;
	[self.queryPredicatesController performFetch:&error];
	NSAssert(error == nil, @"Error: %@", error);
}

#pragma mark -
#pragma mark Table View Data Source Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return (NSInteger)_count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	MADQueryViewSectionDelegate *layoutSection = [self layoutAtIndex:(short)section];
	NSInteger numberOfRows = layoutSection.numberOfRows == NSNotFound ?
					[self numberOfRowsInSection:layoutSection.querySection] : 1;
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
			
			NSIndexPath *fromIndex =    [NSIndexPath indexPathForRow: fromIndexPath.row
														   inSection: 0],
						*toIndex =      [NSIndexPath indexPathForRow: toIndexPath.row
														   inSection: 0];
			
			RptqQueryGroup *fromGroup = [_queryGroupsController objectAtIndexPath: fromIndex],
						   *toGroup =   [_queryGroupsController objectAtIndexPath: toIndex];
			
			fromGroup.weight = toGroup.weight;
			toGroup.weight = fromGroup.weight;

			MADocument *document = self.datasoruce.document;
			
			NSError *error = nil;
			[(self.queryGroupsController).managedObjectContext save:&error];
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
			NSAttributedString *message = [MADAttributedStringQueryController attributedStringForQuerySectionDatasourceWithMessage: localizedMessage
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
			RptqQueryTable *tablea = [self.queryTablesController objectAtIndexPath: path];
			cell.textLabel.text = tablea.alias.copy;

			break;

		}
			
			// MARK: Display the table links or joins that are used in the query.
		case MADIdentifierQueryViewSectionsLinks: {
			
			static NSString *MADIDCellInstruction = @"MADIdentifierCellQueryLink";
			cell = [tableView dequeueReusableCellWithIdentifier: MADIDCellInstruction];
			
			NSIndexPath *indexPathLinks = [NSIndexPath indexPathForRow: row inSection: 0];
			RptqQueryLinks *links = [self.queryLinksController objectAtIndexPath: indexPathLinks];
			
			NSString *leftString = [MADStringQueryController stringForFieldDisplayWithTable: links.tableLeftID
																				   andField: links.fieldLeftID];
			
			NSString *rightString = [MADStringQueryController stringForFieldDisplayWithTable: links.tableRightID
																					andField: links.fieldRightID];
			
			NSAttributedString *message;
			message = [MADAttributedStringQueryController attributedStringForQuerySectionLinksWithLeftString: leftString
																				   rightString: rightString
																			  linksDescription: [links linkDescription]];
			((MADTableViewCellQueryLink *)cell).linkID = links.objectID.copy;
			cell.textLabel.attributedText = message;

			break;
		}
			
			// MARK: Display the groupings used in the query.
		case MADIdentifierQueryViewSectionsGroups: {
			
			static NSString *MADIDCellInstruction = @"MADIdentifierQueryGroup";
			cell = [tableView dequeueReusableCellWithIdentifier: MADIDCellInstruction];
			
			
			NSIndexPath *path = [NSIndexPath indexPathForRow: row inSection: 0];
			RptqQueryGroup *group = [self.queryGroupsController objectAtIndexPath: path];
			cell.backgroundView.backgroundColor = [UIColor whiteColor];
			
			NSString *field = [group fieldNameNice].copy,
			*sort  = [group sortDisplayNice].copy;
			NSAttributedString *message;
			message = [MADAttributedStringQueryController attributedStringForQuerySectionGroupWithField: field
																								andSort: sort];
			cell.textLabel.attributedText = message;
			((MADTableViewCellQueryGroup *)cell).groupID = group.objectID.copy;

			break;
		}
			
			// MARK: Display the predicates or conditions on the query.
		case MADIdentifierQueryViewSectionsPredicate: {
			static NSString *MADIDCellPredicate = @"MADIdentifierQueryPredicate";
			cell = [tableView dequeueReusableCellWithIdentifier: MADIDCellPredicate];
			NSIndexPath *indexPathPredicates = [NSIndexPath indexPathForRow: row inSection: 0];
			RptqQueryPredicate *predicate = [self.queryPredicatesController objectAtIndexPath: indexPathPredicates];

			NSString *leftFieldDisplay, *rightFieldDisplay, *symbol = [predicate symbolForDisplay];
			if (predicate.leftFieldID != nil) {
				leftFieldDisplay = predicate.leftFieldID;
			} else {
				leftFieldDisplay = [predicate.hasLeftField toString];
			}
			
			if (predicate.rightFieldID != nil) {
				rightFieldDisplay = predicate.rightFieldID;
			} else {
				rightFieldDisplay = [predicate.hasRightField toString];
			}
			NSAttributedString *message;
			message = [MADAttributedStringQueryController attributedStringForQueryPredicateWithLeftText: leftFieldDisplay
																					 symbol: symbol
																				  rightText: rightFieldDisplay];
			((MADTableViewCellQueryPredicate *)cell).predicateID = predicate.objectID.copy;
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

- (NSFetchedResultsController *)queryLinksController {
	if (_queryLinksController == nil) {
		NSString *key = NSStringFromSelector(@selector(tableLeftID));
		NSString *entityName = NSStringFromClass([RptqQueryLinks class]);
		NSSortDescriptor *sortDescriptor;
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey: key
													 ascending: YES];
		
		NSFetchedResultsController *frc;
		NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: entityName];
		MADocument *doc = self.datasoruce.document;
		NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
		request.sortDescriptors = sortDescriptors;
		frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
												  managedObjectContext: doc.managedObjectContext
													sectionNameKeyPath: nil
															 cacheName: nil];
		frc.delegate = self;
		_queryLinksController = frc;
	}
	return _queryLinksController;
}

- (NSFetchedResultsController *)queryGroupsController {
	if (_queryGroupsController == nil) {

		MADocument *doc;
		NSFetchedResultsController *frc;
		NSSortDescriptor *sortDescriptor;
		NSArray *sortDescriptors;
		
		NSString *keyWeight = NSStringFromSelector(@selector(weight));
		NSString *entityName = NSStringFromClass([RptqQueryGroup class]);

		sortDescriptor = [[NSSortDescriptor alloc] initWithKey: keyWeight
													 ascending: YES];
		NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: entityName];
		
		sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
		
		request.sortDescriptors = sortDescriptors;
		doc = self.datasoruce.document;
		frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
												  managedObjectContext: doc.managedObjectContext
													sectionNameKeyPath: nil
															 cacheName: nil];
		frc.delegate = self;
		_queryGroupsController = frc;
	}
	return _queryGroupsController;
}

- (NSFetchedResultsController *)queryTablesController {
	if (_queryTablesController == nil) {
		NSString *entityName = NSStringFromClass([RptqQueryTable class]);
		NSString *keyAlias = NSStringFromSelector(@selector(alias));
		NSString *keyIdentifier = NSStringFromSelector(@selector(identifier));
		NSString *keyInQuery = NSStringFromSelector(@selector(inQuery));
		keyInQuery = [MADStringUtilities stringByAppendingPeriod: keyInQuery];
		keyInQuery = [keyInQuery stringByAppendingString:keyIdentifier];

		id predicate;
		NSExpression *predicateExpression[2];
		
		predicateExpression[0] = [NSExpression expressionForKeyPath:keyInQuery];
		MADocument *doc = self.datasoruce.document;
		MADModelQuery *query = doc.documentModel.firstQuery;
		NSNumber *identifier = @(query.identifier);
		predicateExpression[1] = [NSExpression expressionForConstantValue: identifier];

		predicate = [NSComparisonPredicate predicateWithLeftExpression: predicateExpression[0]
													   rightExpression: predicateExpression[1]
															  modifier: NSDirectPredicateModifier
																  type: NSEqualToPredicateOperatorType
															   options: 0];
		NSSortDescriptor *sortDescriptor;
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey: keyAlias
													 ascending: YES];
		//NSFetchedResultsController *frc;
		NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: entityName];
		NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
		request.sortDescriptors = sortDescriptors;
		request.predicate = predicate;
		NSFetchedResultsController *frc;
		frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
												  managedObjectContext: doc.managedObjectContext
													sectionNameKeyPath: nil
															 cacheName: nil];
		frc.delegate = self;
		_queryTablesController = frc;
	}
	return _queryTablesController;
}

- (NSFetchedResultsController *)queryPredicatesController {
	if (_queryPredicatesController == nil) {
		NSString *keyLeftFieldID = NSStringFromSelector(@selector(leftFieldID));
		NSString *entityName = NSStringFromClass([RptqQueryPredicate class]);
		MADocument *doc = self.datasoruce.document;
		NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: entityName];
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: keyLeftFieldID
																	   ascending: YES];
		NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
		request.sortDescriptors = sortDescriptors;
		NSFetchedResultsController *frc;
		frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
												  managedObjectContext: doc.managedObjectContext
													sectionNameKeyPath: nil
															 cacheName: nil];
		frc.delegate = self;
		_queryPredicatesController = frc;
	}
	return _queryPredicatesController;
}

@end
