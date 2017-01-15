//
//  MADQueryViewControllerLayout.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryViewDataSource.h"

#import "MADTableViewCellQueryTableName.h"
#import "MADTableViewCellQueryLink.h"
#import "MADTableViewCellQueryPredicate.h"
#import "MADTableViewCellQueryGroup.h"

#import "NSAttributedString+QueryViewController.h"

#import "MADQueryViewSectionDelegate.h"

#import <CoreData/NSFetchedResultsController.h>
#import <CoreData/NSManagedObjectID.h>

#import <MAD/MADocument.h>

#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqQuery+Extras.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqQueryGroup+Extras.h>
#import <MAD/RptqQueryLinks+Extras.h>
#import <MAD/RptqQueryPredicate+Extras.h>
#import <MAD/RptqUserCredentals+Extras.h>

#import <Foundation/NSIndexPath.h>
#import <UIKit/UITableView.h>
#import <UIKit/UILabel.h>

static NSString * const TextFormatConnection = @"You are connecting to %1$@"
                                               @" datasource named %2$@.";

@interface MADQueryViewDataSource ()
    <NSFetchedResultsControllerDelegate>

    @property (nonatomic, weak) MADocument *document;

    @property (nonatomic, readwrite, assign) short count;
    @property (nonatomic, readwrite, assign) NSUInteger numberOfTables;

    @property (nonatomic, readwrite, strong) NSArray <__kindof MADQueryViewSectionDelegate *> *sections;

    @property (nonatomic, readwrite, weak) MADQueryViewCellConfigureHandler handleConfigureCell;

@end

@implementation MADQueryViewDataSource {
    BOOL _reportingEnabled;
}

- (void)dealloc {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    //_sections = nil;
    _handleConfigureCell = nil;
    _datasoruce = nil;
    if (_queryLinksController) {
        _queryLinksController.delegate = nil;
//        _queryLinksController = nil;
    }
    if (_queryTablesController) {
        _queryTablesController.delegate = nil;
//        _queryTablesController = nil;
    }
    if (_queryGroupsController) {
        _queryGroupsController.delegate = nil;
//        _queryGroupsController = nil;
    }
    if (_queryPredicatesController) {
        _queryPredicatesController.delegate = nil;
//        _queryPredicatesController = nil;
    }
}

- (instancetype)initWithDocument:(MADocument *)document
                reportingEnabled:(BOOL)reportingEnabled
             handleConfigureCell:(MADQueryViewCellConfigureHandler)handleConfigureCell {
    
    if (self = [super init]) {
        
        NSUInteger numberOfTables;
        NSSet *hasDatabaseSchemas, *hasQueries, *hasQueryTables;
        RptqDocument *rptqDocument;
        RptqDatabase *rptqDatabase;
        RptqQuery *rptqQuery;
        
        rptqDocument = [document activeDocumentModel];
        
        hasDatabaseSchemas = rptqDocument.hasDatabaseSchemas;
        rptqDatabase = hasDatabaseSchemas.anyObject;
        hasQueries = rptqDatabase.hasQueries;
        rptqQuery = hasQueries.anyObject;
        hasQueryTables = rptqQuery.hasQueryTables;
        numberOfTables = hasQueryTables.count;
        
        short count;
        switch (numberOfTables) {
            case 0:
                count = reportingEnabled ? 3 : 2;
                break;
            case 1:
                count = reportingEnabled ? 5 : 4;
                break;
            default:
                count = reportingEnabled ? 6 : 5;
                break;
        }
        
        _reportingEnabled = reportingEnabled;
        _numberOfTables = numberOfTables;
        _count = count;
        _handleConfigureCell = handleConfigureCell;
        _document = document;
    }
    return self;
    
}

- (instancetype)initWithNumberOfTables:(NSUInteger)numberOfTables
                      reportingEnabled:(BOOL)reportingEnabled
                   handleConfigureCell:(MADQueryViewCellConfigureHandler)handleConfigureCell {

    if (self = [super init]) {
        
        short count;
        switch (numberOfTables) {
            case 0:
                count = reportingEnabled ? 3 : 2;
                break;
            case 1:
                count = reportingEnabled ? 5 : 4;
                break;
            default:
                count = reportingEnabled ? 6 : 5;
                break;
        }
        
        _reportingEnabled = reportingEnabled;
        _numberOfTables = numberOfTables;
        _count = count;
        _handleConfigureCell = handleConfigureCell;
        
    }
    return self;
}

- (void)numberOfTablesChanged:(NSUInteger)numberOfTables {
    short count;
    switch (numberOfTables) {
        case 0:
            count = _reportingEnabled ? 3 : 2;
            break;
        case 1:
            count = _reportingEnabled ? 5 : 4;
            break;
        default:
            count = _reportingEnabled ? 6 : 5;
            break;
    }
    
    _numberOfTables = numberOfTables;
    _count = count;
    _sections = nil;
}

- (MADIdentifierQueryViewSections)sectionAtIndex:(short)index {
    MADQueryViewSectionDelegate *layout;
    layout = [[MADQueryViewSectionDelegate alloc] initWithNumberOfTables:_numberOfTables position:index];
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
    NSMutableSet <__kindof NSNumber *> *sectionTypes = [[NSMutableSet alloc] initWithCapacity:(NSUInteger)_count];
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

- (NSInteger)numberOfRowsInSectionAtIndex:(short)index {
    MADQueryViewSectionDelegate *layoutSection = [self layoutAtIndex:(short)index];
    NSInteger numberOfSections = layoutSection.numberOfRows == NSNotFound ?
                                    [self numberOfRowsInSection:layoutSection.querySection] : 1;
    return numberOfSections;
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

- (void)performFetchWithController:(NSFetchedResultsController *)controller {
    if (controller) {
        NSError * __autoreleasing error = NULL;
        [controller performFetch:&error];
        NSAssert(error == NULL, @"Error: %@", error);
    }
    [self.datasoruce reloadQueryViewData];
}

- (void)performFetchAll {
    [self performFetchTables];
    [self performFetchLinks];
    [self performFetchGroups];
    [self performFetchPredicate];
}

- (void)performFetchTables {
    [self performFetchWithController:self.queryTablesController];
}

- (void)performFetchLinks {
    [self performFetchWithController:self.queryLinksController];
}

- (void)performFetchGroups {
    [self performFetchWithController:self.queryGroupsController];
}

- (void)performFetchPredicate {
    [self performFetchWithController:self.queryPredicatesController];
}

#pragma mark -
#pragma mark Table View Data Source Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger count = (NSInteger)self.count;
    //NSLog(@"Number of sections in table view: %ld", (long)count);
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = [self numberOfRowsInSectionAtIndex:(short)section];
    //NSLog(@"Section %ld has %ld rows.", section, rows);
    return rows;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self canEditSectionAtIndex:(short)indexPath.section];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return ([self sectionAtIndex:(short)indexPath.section] == MADIdentifierQueryViewSectionsGroups);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style
                                            forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //NSLog(@"Commit editing style for index path: (%ld, %ld)", (long)indexPath.section, indexPath.row);
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

    //NSLog(@"Move row at (%ld, %ld) to (%ld, %ld).", fromIndexPath.section, fromIndexPath.row, toIndexPath.section, toIndexPath.row);

    switch ([self sectionAtIndex:(short)toIndexPath.section]) {
        case MADIdentifierQueryViewSectionsGroups: {
            
            NSIndexPath *fromIndex =    [NSIndexPath indexPathForRow: fromIndexPath.row
                                                           inSection: 0],
                        *toIndex =      [NSIndexPath indexPathForRow: toIndexPath.row
                                                           inSection: 0];
            
            RptqQueryGroup *fromGroup = [_queryGroupsController objectAtIndexPath: fromIndex],
                           *toGroup =   [_queryGroupsController objectAtIndexPath: toIndex];
            
            id fromWeight   = [[NSNumber alloc] initWithInteger: toGroup.weight.integerValue],
               toWeight     = [[NSNumber alloc] initWithInteger: fromGroup.weight.integerValue];
            
            fromGroup.weight = fromWeight;
            toGroup.weight = toWeight;
            
            NSError *error = nil;
            [(self.queryGroupsController).managedObjectContext save:&error];

            //[self.document.managedObjectContext save:&error];
            [self performFetchGroups];
            break;
        }
        default:
            break;
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView { return nil; }

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //NSLog(@"Cell for row at index path: (%ld, %ld)", indexPath.section, indexPath.row);

    UITableViewCell *cell = nil;
    
    NSInteger row = indexPath.row;
    MADIdentifierQueryViewSections section = [self sectionAtIndex:(short)indexPath.section];
    
    switch (section) {
            
            // MARK: Display and identify the data source and data sources
        case MADIdentifierQueryViewSectionsDatasource: {
            
            static NSString *MADIdentifierTableViewCellDataSource = @"MADIdentifierTableViewCellDataSource";
            cell = [tableView dequeueReusableCellWithIdentifier: MADIdentifierTableViewCellDataSource];
            
            NSManagedObjectContext *managedObjectContext;
            managedObjectContext = self.document.managedObjectContext;
            RptqDocument *document;
            document = [_document activeDocumentModel];
            RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
            if (database.ownedByUser) {
                
                id databaseType = database.ownedByUser.database_driver_type.copy;
                id schemaName = [database.ownedByUser copyDatabaseSchemaName];
                id localizedMessage = NSLocalizedString(TextFormatConnection, TextFormatConnection);
                id message = [NSAttributedString newAttributedStringQuerySectionDatasourceForMessage: localizedMessage
                                                                                        databaseType: databaseType
                                                                                          schemaName: schemaName];
                UILabel *textLabel = cell.textLabel;
                textLabel.attributedText = message;
                textLabel.text = localizedMessage;
            }
            
            break;
        }
            
            // MARK: Display the table names that are used in the query
        case MADIdentifierQueryViewSectionsTables: {
            
            static NSString *MyIdentifierUITableViewCellTableName = @"MADTableCellSchemaName";
            cell = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellTableName];
            
            NSIndexPath *path = [NSIndexPath indexPathForRow: row inSection: 0];
            RptqQueryTable *tablea = [self.queryTablesController objectAtIndexPath: path];
            cell.textLabel.text = tablea.alias.copy;

            break;

        }
            
            // MARK: Display the table links or joins that are used in the query.
        case MADIdentifierQueryViewSectionsLinks: {
            
            static NSString *MADIDCellInstruction = @"UITableViewCellQueryLink";
            cell = [tableView dequeueReusableCellWithIdentifier: MADIDCellInstruction];
            
            NSIndexPath *indexPathLinks = [NSIndexPath indexPathForRow: row inSection: 0];
            RptqQueryLinks *links = [self.queryLinksController objectAtIndexPath: indexPathLinks];
            
            NSString *leftString = [NSString newStringFieldDisplayWithTable: links.tableleft
                                                                   andField: links.fieldleft];
            
            NSString *rightString = [NSString newStringFieldDisplayWithTable: links.tableright
                                                                    andField: links.fieldright];
            
            NSString *linksDescription = [links copyLinkDescription];
            NSAttributedString *message;
            message = [NSAttributedString newAttributedStringQuerySectionLinks: leftString
                                                                   rightString: rightString
                                                              linksDescription: linksDescription];
            ((MADTableViewCellQueryLink *)cell).tableID = links.objectID.copy;
            cell.textLabel.attributedText = message;

            break;
        }
            
            // MARK: Display the groupings used in the query.
        case MADIdentifierQueryViewSectionsGroups: {
            
            static NSString *MADIDCellInstruction = @"UITableViewCellQueryGroup";
            cell = [tableView dequeueReusableCellWithIdentifier: MADIDCellInstruction];
            
            
            NSIndexPath *path = [NSIndexPath indexPathForRow: row inSection: 0];
            RptqQueryGroup *group = [self.queryGroupsController objectAtIndexPath: path];
            cell.backgroundView.backgroundColor = [UIColor whiteColor];
            
            NSString *field = [group fieldNameNice].copy,
            *sort  = [group sortDisplayNice].copy;
            NSAttributedString *message;
            message = [NSAttributedString newAttributedStringQuerySectionGroupWithField: field
                                                                                andSort: sort];
            cell.textLabel.attributedText = message;
            ((MADTableViewCellQueryGroup *)cell).tableID = group.objectID.copy;

            break;
        }
            
            // MARK: Display the predicates or conditions on the query.
        case MADIdentifierQueryViewSectionsPredicate: {
            static NSString *MADIDCellPredicate = @"UITableViewCellQueryPredicate";
            cell = [tableView dequeueReusableCellWithIdentifier: MADIDCellPredicate];
            NSIndexPath *indexPathPredicates = [NSIndexPath indexPathForRow: row inSection: 0];
            RptqQueryPredicate *predicate = [self.queryPredicatesController objectAtIndexPath: indexPathPredicates];

            NSString *leftFieldDisplay, *rightFieldDisplay, *symbol = [predicate symbolForDisplay];
            if (predicate.fieldleftpred != nil) {
                leftFieldDisplay = predicate.fieldleftpred;
            } else {
                leftFieldDisplay = [predicate.hasLeftField toString];
            }
            
            if (predicate.fieldrightpred != nil) {
                rightFieldDisplay = predicate.fieldrightpred;
            } else {
                rightFieldDisplay = [predicate.hasRightField toString];
            }
            NSAttributedString *message;
            message = [NSAttributedString newAttributedStringQueryPredicate: leftFieldDisplay
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
                    static NSString *MADIDCellQueryInput = @"UITableViewCellQueryInput";
                    cell = [tableView dequeueReusableCellWithIdentifier: MADIDCellQueryInput];
                    break;
                }
            }
            break;
        }
            
        case MADIdentifierQueryViewSectionsNumberOfQueryResults: {
            
            static NSString *idNumberOfQueryResults = @"UITableViewCellNumberOfQueryResultsIdentifier";
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

@end
