//
//  MADQueryViewControllerTableLayout.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/11/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryViewControllerTableLayout.h"
#import "MADTableViewCellQueryTableName.h"
#import "MADTableViewCellQueryLink.h"
#import "MADQueryViewControllerSections.h"
#import "NSDictionary+QueryViewControllerTableLayout.h"
#import "MADQueryViewControllerLayout.h"

@interface MADQueryViewControllerTableLayout ()

    @property (nonatomic, strong) NSDictionary *datamodel;

@end

@implementation MADQueryViewControllerTableLayout

- (instancetype)initWithNumberOfTables:(NSInteger)numberOfTables
                      reportingEnabled:(BOOL)enabled {
    self = [super init];
    if (!self) return nil;
    
    id result;
    switch (numberOfTables) {
    
        case 0:
            result = [NSDictionary newDictionaryQueryLayoutTableZeroReportingEnabled: enabled];
            break;
            
        case 1:
            result = [NSDictionary newDictionaryQueryLayoutTableOneReportingEnabled: enabled];
            break;
            
        default:
            result = [NSDictionary newDictionaryQueryLayoutTableMoreThanOneReportingEnabled: enabled];
            break;
            
    }
    self.datamodel = result;
    
    return self;
}

- (NSArray *)sectionTypes {
    id sections = _datamodel[MTTableSectionSectionsKey];
    NSArray *sectionTypes = sections != nil ?
                    [[NSArray alloc] initWithArray: sections] :
                    nil;
    return sectionTypes;
}

#pragma mark -
#pragma mark Table View Data Source Protocol
/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)self.datamodel.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    
    MADQueryViewControllerLayout *datamodel = self.datamodel;
    MADQueryViewControllerLayoutSection *layoutSection = [datamodel layoutAtIndex:(short)section];
    
    NSInteger numberOfRows = 1;
    if (layoutSection.numberOfRows == NSNotFound) {
        id<NSFetchedResultsSectionInfo> sectionData;
        switch (layoutSection.querySection) {
            case MADQueryViewControllerSectionsTables: {
                sectionData = self.queryTablesController.sections[0];
                numberOfRows = (NSInteger)sectionData.numberOfObjects;
                break;
            }
            case MADQueryViewControllerSectionsLinks: {
                sectionData = self.queryLinksController.sections[0];
                numberOfRows = (NSInteger)sectionData.numberOfObjects;
                break;
            }
            case MADQueryViewControllerSectionsPredicate: {
                sectionData = self.queryPredicatesController.sections[0];
                numberOfRows = (NSInteger)sectionData.numberOfObjects;
                break;
            }
            case MADQueryViewControllerSectionsGroups: {
                sectionData = self.queryGroupsController.sections[0];
                numberOfRows = (NSInteger)sectionData.numberOfObjects;
                break;
            }
            default:
                numberOfRows = 0;
                break;
        }
    }
	return numberOfRows;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    MADQueryViewControllerSections sectionType = [self.datamodel sectionAtIndex:(short)indexPath.section];
	return (sectionType == MADQueryViewControllerSectionsTables ||
            sectionType == MADQueryViewControllerSectionsGroups ||
            sectionType == MADQueryViewControllerSectionsPredicate ||
            sectionType == MADQueryViewControllerSectionsLinks);
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return ([self.datamodel sectionAtIndex:(short)indexPath.section] == MADQueryViewControllerSectionsGroups);
}

- (void)tableView:(UITableView *)tableView
                                commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
                                 forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MADQueryViewControllerSections querySection = [self.datamodel sectionAtIndex:(short)indexPath.section];

    switch (editingStyle) {

        case UITableViewCellEditingStyleDelete:
            [self deleteItemFromQuerySection:querySection fromTableView:tableView atIndexPath:indexPath];
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
    
    MADQueryViewControllerSections ts = [self.datamodel sectionAtIndex:(short)toIndexPath.section];
    switch (ts) {
        case MADQueryViewControllerSectionsGroups: {

            NSIndexPath *fromIndex = [NSIndexPath indexPathForRow: fromIndexPath.row inSection: 0],
                        *toIndex = [NSIndexPath indexPathForRow: toIndexPath.row inSection: 0];
            RptqQueryGroup *fromGroup = [self.queryGroupsController objectAtIndexPath: fromIndex],
                           *toGroup = [self.queryGroupsController objectAtIndexPath: toIndex];
            
            id fromWeight = [[NSNumber alloc] initWithInteger: toGroup.weight.integerValue],
               toWeight = [[NSNumber alloc] initWithInteger: fromGroup.weight.integerValue];

            fromGroup.weight = fromWeight;
            toGroup.weight = toWeight;

            NSError *error = nil;
            [(self.queryGroupsController).managedObjectContext save:&error];
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
    
    UITableViewCell *result = nil;

    NSInteger row = indexPath.row;
    MADQueryViewControllerSections section = [self.datamodel sectionAtIndex:(short)indexPath.section];

    switch (section) {

        // MARK: Display and identify the data source and data sources
        case MADQueryViewControllerSectionsDatasource: {
        
            static NSString *MADIdentifierTableViewCellDataSource = @"MADIdentifierTableViewCellDataSource";
            result = [tableView dequeueReusableCellWithIdentifier: MADIdentifierTableViewCellDataSource];

            RptqDatabase *database = self.document.activeDocumentModel.hasDatabaseSchemas.anyObject;
            if (database.ownedByUser) {

                id databaseType = database.ownedByUser.database_driver_type.copy;
                id schemaName = [database.ownedByUser copyDatabaseSchemaName];
                id localizedMessage = NSLocalizedString(TextFormatConnection, TextFormatConnection);
                id message = [NSAttributedString newAttributedStringQuerySectionDatasourceForMessage: localizedMessage
                                                                                        databaseType: databaseType
                                                                                          schemaName: schemaName];
                
                result.textLabel.attributedText = message;
                result.detailTextLabel.text = @"";
                result.tintColor = [MADColorEverydayApps newColorBlackTwentyFivePercent];

            }
            result.textLabel.numberOfLines = 0;
            break;
        }

        // MARK: Display the table names that are used in the query
        case MADQueryViewControllerSectionsTables: {
        
            static NSString *MyIdentifierUITableViewCellTableName = @"UITableViewCellTableName";
            result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierUITableViewCellTableName];
            NSIndexPath *path = [NSIndexPath indexPathForRow: row inSection: 0];
            RptqQueryTable *tablea = [self.queryTablesController objectAtIndexPath: path];
            NSString *alias = tablea.alias.copy;
            UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            result.textLabel.text = alias;
            result.textLabel.font = font;
            result.textLabel.backgroundColor = [UIColor whiteColor];
            result.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            result.indentationLevel = 1;
            result.tintColor = [MADColorEverydayApps newColorBlue];
            result.backgroundColor = [UIColor whiteColor];
            break;
        }
        
        // MARK: Display the table links or joins that are used in the query.
        case MADQueryViewControllerSectionsLinks: {

            static NSString *MADIDCellInstruction = @"UITableViewCellQueryLink";
            result = [tableView dequeueReusableCellWithIdentifier: MADIDCellInstruction];
            NSIndexPath *indexPathLinks = [NSIndexPath indexPathForRow: row inSection: 0];
            RptqQueryLinks *links = [self.queryLinksController objectAtIndexPath: indexPathLinks];
            
            NSString *leftString = [NSString newStringFieldDisplayWithTable:links.tableleft
                                                                   andField:links.fieldleft];

            NSString *rightString = [NSString newStringFieldDisplayWithTable:links.tableright
                                                                    andField:links.fieldright];

            NSString *linksDescription = [links copyLinkDescription];
            NSAttributedString *message;
            message = [NSAttributedString newAttributedStringQuerySectionLinks:leftString
                                                                   rightString:rightString
                                                              linksDescription: linksDescription];
            ((MADTableViewCellQueryLink *)result).tableID = links.objectID.copy;
            result.textLabel.numberOfLines = 0;
            result.textLabel.attributedText = message;

            break;
        }

        // MARK: Display the groupings used in the query.
        case MADQueryViewControllerSectionsGroups: {
            static NSString *MADIDCellInstruction = @"UITableViewCellQueryGroup";
            result = [tableView dequeueReusableCellWithIdentifier: MADIDCellInstruction];
            NSIndexPath *path = [NSIndexPath indexPathForRow: row inSection: 0];
            RptqQueryGroup *group = [self.queryGroupsController objectAtIndexPath: path];
            result.backgroundView.backgroundColor = [UIColor whiteColor];
            
            NSString *field = [group fieldNameNice].copy,
                     *sort  = [group sortDisplayNice].copy;
            NSAttributedString *message;
            message = [NSAttributedString newAttributedStringQuerySectionGroupWithField: field
                                                                                andSort: sort];
            result.textLabel.attributedText = message;
            result.textLabel.numberOfLines = 0;
            ((MADTableViewCellQueryGroup *)result).tableID = group.objectID.copy;
            break;
        }
        
        // MARK: Display the predicates or conditions on the query.
        case MADQueryViewControllerSectionsPredicate: {
            static NSString *MADIDCellPredicate = @"UITableViewCellQueryPredicate";
            result = [tableView dequeueReusableCellWithIdentifier: MADIDCellPredicate];
            
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
            result.textLabel.numberOfLines = 0;
            result.textLabel.attributedText = message;
            ((MADTableViewCellQueryPredicate *)result).tableID = predicate.objectID.copy;
            
            break;
        }
        
        case MADQueryViewControllerSectionsSql: {
            switch (row) {
                case 0: {
                    static NSString *MADIDCellOverride = @"UITableViewCellOverride";
                    result = [tableView dequeueReusableCellWithIdentifier: MADIDCellOverride];
                    break;
                }
                default: {
                    static NSString *MADIDCellQueryInput = @"UITableViewCellQueryInput";
                    result = [tableView dequeueReusableCellWithIdentifier: MADIDCellQueryInput];
                    break;
                }
            }
            break;
        }
            
        case MADQueryViewControllerSectionsNumberOfQueryResults: {
        
            static NSString *idNumberOfQueryResults = @"UITableViewCellNumberOfQueryResultsIdentifier";
            result = [tableView dequeueReusableCellWithIdentifier: idNumberOfQueryResults];
            UISwitch *s = [[UISwitch alloc] initWithFrame:CGRectZero];
            s.on = [[NSUserDefaults standardUserDefaults] boolForKey:MADIdentifierDefaultsViewerDesired];
            [s addTarget:self action:@selector(handleToggleReportingMode:) forControlEvents:UIControlEventValueChanged];
            result.accessoryView = s;
            result.textLabel.text = [[NSUserDefaults standardUserDefaults] boolForKey:MADIdentifierDefaultsViewerDesired] ?
                                                    @"Reporting Mode" : @"Designer Mode (limited)";
            break;
        }
        
        default: {
            break;
        }

    }
    
    if (!result) {
        result = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCellShouldNotGetHere"];
        (result.textLabel).text = @"Err";
    }

    return result;
}
*/
@end
