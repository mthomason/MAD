//
//  MADQueryViewControllerLayout.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/6/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryViewDataSource.h"

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

#import <MADFoundation/NSString+Common.h>

#import "MADTableViewCellQueryTableName.h"
#import "MADTableViewCellQueryLink.h"
#import "MADTableViewCellQueryPredicate.h"
#import "MADTableViewCellQueryGroup.h"

#import "NSAttributedString+QueryViewController.h"

#import "MADQueryViewSectionDelegate.h"
#import "MADQueryViewDatasourceProtocol.h"

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
    //NSLog(@"%s", __PRETTY_FUNCTION__);
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
    
        NSString *keyHasQueryTables = @"madQTC";
        
        NSArray <NSDictionary <NSString *, NSNumber *> *> *result;
        NSError * __autoreleasing *error = NULL;
        NSFetchRequest *request = [RptqQuery fetchRequestTableCount:queryID
                                                      objectContext:managedObjectContext];
        
        NSUInteger numberOfTables = 0;

        result = [managedObjectContext executeFetchRequest:request error:error];
        if (result.count > 0)
            numberOfTables = (NSUInteger)[result[0][keyHasQueryTables] integerValue];
        
        _count = numberOfSectionsForQueryTableCount(numberOfTables, reportingEnabled);
        _reportingEnabled = reportingEnabled;
        _numberOfTables = (unsigned long)numberOfTables;
        _handleConfigureCell = handleConfigureCell;
        
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
    NSLog(@"%s: (%ld)", __PRETTY_FUNCTION__, numberOfTables);
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
        [sectionTypes addIndex:section.querySection];
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
    NSError * __autoreleasing error = NULL;
    [self.queryTablesController performFetch:&error];
    NSAssert(error == NULL, @"Error: %@", error);
}

- (void)performFetchLinks {
    NSError * __autoreleasing error = NULL;
    [self.queryLinksController performFetch:&error];
    NSAssert(error == NULL, @"Error: %@", error);
}

- (void)performFetchGroups {
    NSError * __autoreleasing error = NULL;
    [self.queryGroupsController performFetch:&error];
    NSAssert(error == NULL, @"Error: %@", error);
}

- (void)performFetchPredicate {
    NSError * __autoreleasing error = NULL;
    [self.queryPredicatesController performFetch:&error];
    NSAssert(error == NULL, @"Error: %@", error);
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
    //NSLog(@"%s %ld: %ld", __PRETTY_FUNCTION__, (long)section, numberOfRows);
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
    
    //NSLog(@"Commit editing style for index path: (%ld, %ld)",
    //      (long)indexPath.section, indexPath.row);
    switch (style) {
            
        case UITableViewCellEditingStyleDelete:
            [self.datasoruce deleteItemFromQuerySection: [self sectionAtIndex:(short)indexPath.section]
                                          fromTableView: tableView
                                            atIndexPath: indexPath];
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
            
            NSError *error = nil;
            [(self.queryGroupsController).managedObjectContext save:&error];

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
            NSString *databaseType = db.driverID.copy;
            NSString *schemaName = db.schemaName.copy;
            
            NSString *TextFormatConnection = @"You are connecting to %1$@"
            @" datasource named %2$@.";
            NSString *localizedMessageFormat;
            NSString *localizedMessage;
            NSAttributedString *message;
            localizedMessageFormat = NSLocalizedString(TextFormatConnection, TextFormatConnection);
            localizedMessage = [[NSString alloc] initWithFormat:localizedMessageFormat, databaseType, schemaName];
            message = [MADAttributedStringQueryController newAttributedStringQuerySectionDatasourceForMessage: localizedMessage
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
            
            NSString *leftString = [MADStringQueryController newStringFieldDisplayWithTable: links.tableLeftID
                                                                                   andField: links.fieldLeftID];
            
            NSString *rightString = [MADStringQueryController newStringFieldDisplayWithTable: links.tableRightID
                                                                                    andField: links.fieldRightID];
            
            NSAttributedString *message;
            message = [MADAttributedStringQueryController newAttributedStringQuerySectionLinks: leftString
                                                                                   rightString: rightString
                                                                              linksDescription: [links linkDescription]];
            ((MADTableViewCellQueryLink *)cell).tableID = links.objectID.copy;
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
            message = [MADAttributedStringQueryController newAttributedStringQuerySectionGroupWithField: field
                                                                                                andSort: sort];
            cell.textLabel.attributedText = message;
            ((MADTableViewCellQueryGroup *)cell).tableID = group.objectID.copy;

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
            message = [MADAttributedStringQueryController newAttributedStringQueryPredicate: leftFieldDisplay
                                                                                     symbol: symbol
                                                                                  rightText: rightFieldDisplay];
            ((MADTableViewCellQueryPredicate *)cell).tableID = predicate.objectID.copy;
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
        keyInQuery = [keyInQuery stringByAppendingPeriod];
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
