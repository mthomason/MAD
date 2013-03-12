//
//  UITableViewControllerLinkBuilder.m
//  Reports
//
//  Created by Michael Thomason on 1/26/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderLinkBuilderViewController.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"
#import "AppDelegate.h"

@interface MTQueryBuilderLinkBuilderViewController ()

@property (nonatomic, retain) RptqDatabaseSchemaTable *firstTableName;
@property (nonatomic, retain) RptqDatabaseSchemaTable *secondTableName;
@property (nonatomic, retain) RptqDatabaseSchemaField *firstFieldName;
@property (nonatomic, retain) RptqDatabaseSchemaField *secondFieldName;

@end

@implementation MTQueryBuilderLinkBuilderViewController

@synthesize delegate = _delegate;
@synthesize tableViewCellJoinType = _tableViewCellJoinType;
@synthesize tableViewCellTableOne = _tableViewCellTableOne;
@synthesize tableViewCellFieldOne = _tableViewCellFieldOne;
@synthesize tableViewCellTableTwo = _tableViewCellTableTwo;
@synthesize tableViewCellFieldTwo = _tableViewCellFieldTwo;
@synthesize tableViewCellTableFieldOne = _tableViewCellTableFieldOne;
@synthesize tableViewCellTableFieldTwo = _tableViewCellTableFieldTwo;
@synthesize linkType = _linkType;
@synthesize firstTableFieldName = _firstTableFieldName, secondTableFieldName = _secondTableFieldName;
@synthesize currentlyEditingPart = _currentlyEditingPart;

- (void)dealloc {
    [_firstTableFieldName release];
    [_secondTableFieldName release];
    [_firstTableName release];
    [_firstFieldName release];
    [_secondTableName release];
    [_tableViewCellJoinType release];
    [_tableViewCellTableOne release];
    [_tableViewCellFieldOne release];
    [_tableViewCellTableTwo release];
    [_tableViewCellFieldTwo release];
    [_tableViewCellTableFieldOne release];
    [_tableViewCellTableFieldTwo release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setCurrentlyEditingPart: MNSLinkNone];
        [[self tableViewCellTableFieldTwo] setUserInteractionEnabled:NO];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setCurrentlyEditingPart: MNSLinkNone];
        [[self tableViewCellTableFieldTwo] setUserInteractionEnabled:NO];
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showSelectJoinType"]) {
        NSLog(@"Class: %@", NSStringFromClass([[segue destinationViewController] class]));
        
        if ([[segue destinationViewController] isKindOfClass: [MTQueryBuilderAddLinkJoinTypeViewController class]]) {
            MTQueryBuilderAddLinkJoinTypeViewController *vcFf = [segue destinationViewController];
            if (vcFf) {
                [vcFf setDelegate: self];
            }
        }

    } else {
        
        if ([[segue identifier] isEqualToString:@"showSelectTableOne"]) {
            NSLog(@"Class: %@", NSStringFromClass([[segue destinationViewController] class]));
            if ([[segue destinationViewController] isKindOfClass: [MTQueryBuilderAddLinkFirstTableViewController class]]) {
                MTQueryBuilderAddLinkFirstTableViewController *tvc = [segue destinationViewController];
                if (tvc) {
                    [tvc setDelegate:self];
                    
                    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
                    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
                    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
                    RptqQuery *query = [[database hasQueries] anyObject];
                    
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDatabaseSchemaTable class])];
                    request.predicate = [NSPredicate predicateWithFormat:@"ANY inQuery == %@", [query objectID]];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES];
                    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                    NSLog(@"[[tvc managedDocumentQuery] managedObjectContext]: %@", [[AppDelegate activeDocument] managedObjectContext]);
                    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                          managedObjectContext: [[AppDelegate activeDocument] managedObjectContext]
                                                                                            sectionNameKeyPath: nil
                                                                                                     cacheName: nil];
                    [tvc setFetchedResultsController: frc];
                    [frc release];
                }
            }
        } else if ([[segue identifier] isEqualToString:@"showSelectFieldOne"]) {
            NSLog(@"Class: %@", NSStringFromClass([[segue destinationViewController] class]));
            if ([[segue destinationViewController] isKindOfClass: [MTQueryBuilderAddLinkFirstFieldViewController class]]) {
                MTQueryBuilderAddLinkFirstFieldViewController *vcFf = [segue destinationViewController];
                if (vcFf) {
                    [vcFf setDelegate:self];                    
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDatabaseSchemaField class])];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES];
                    request.predicate = [NSPredicate predicateWithFormat:@"inTable.name == %@", [[self firstTableName] name]];
                    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                          managedObjectContext: [[AppDelegate activeDocument] managedObjectContext]
                                                                                            sectionNameKeyPath: nil
                                                                                                     cacheName: nil];
                    [vcFf setFetchedResultsController: frc];
                    [frc release];
                }
            }
        } else if ([[segue identifier] isEqualToString:@"showSelectTableTwo"]) {
            NSLog(@"Class: %@", NSStringFromClass([[segue destinationViewController] class]));
            if ([[segue destinationViewController] isKindOfClass: [MTQueryBuilderAddLinkSecondTableViewController class]]) {
                MTQueryBuilderAddLinkSecondTableViewController *vcFf = [segue destinationViewController];
                if (vcFf) {                
                    [vcFf setDelegate:self];                    

                    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
                    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
                    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
                    RptqQuery *query = [[database hasQueries] anyObject];

                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDatabaseSchemaTable class])];
                    request.predicate = [NSPredicate predicateWithFormat:@"ANY inQuery == %@", query];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES];
                    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name != %@", [[self firstTableName] name]];
                    [request setPredicate: predicate];
                    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                          managedObjectContext: [[AppDelegate activeDocument] managedObjectContext]
                                                                                            sectionNameKeyPath: nil
                                                                                                     cacheName: nil];
                    [vcFf setFetchedResultsController: frc];
                    [frc release];
                }
            }
        } else if ([[segue identifier] isEqualToString:@"showSelectFieldTwo"]) {
            NSLog(@"Class: %@", NSStringFromClass([[segue destinationViewController] class]));
            if ([[segue destinationViewController] isKindOfClass: [MTQueryBuilderAddLinkSecondFieldViewController class]]) {
                MTQueryBuilderAddLinkSecondFieldViewController *vcFf = [segue destinationViewController];
                if (vcFf) {                
                    [vcFf setDelegate:self];
                    
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDatabaseSchemaField class])];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES];
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable.name == %@", [[self secondTableName] name]];
                    request.predicate = predicate;
                    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                          managedObjectContext: [[AppDelegate activeDocument] managedObjectContext]
                                                                                            sectionNameKeyPath: nil
                                                                                                     cacheName: nil];
                    [vcFf setFetchedResultsController: frc];
                    [frc release];
                }
            }
        } else if ([[segue identifier] isEqualToString:@"showSelectLinkTableFieldOne"]) {
            
            [self setCurrentlyEditingPart: MNSLinkLeft];
            
            MTQueryBuilderChooseFieldViewController *dvc = [segue destinationViewController];
            if (dvc != nil) {
                [dvc setExcludeTables: ([[self secondTableName] name] ? [NSArray arrayWithObject:[[self secondTableName] name]] : [NSArray array])];
                [dvc setDelegate: self];
            }

        } else if ([[segue identifier] isEqualToString:@"showSelectLinkTableFieldTwo"]) {
            
            [self setCurrentlyEditingPart: MNSLinkRight];
            
            MTQueryBuilderChooseFieldViewController *dvc = [segue destinationViewController];
            if (dvc != nil) {
                [dvc setExcludeTables: ([[self firstTableName] name] ? [NSArray arrayWithObject:[[self firstTableName] name]] : [NSArray array])];
                [dvc setDelegate: self];
            }

        }
    }
}


#pragma mark - Actions

- (IBAction)done:(id)sender {
    
}

- (IBAction)save:(id)sender {
    RptqQueryLinks *queryLink = [RptqQueryLinks createQueryLinkWithLeftField:[self firstFieldName] rightField:[self secondFieldName] andJoinType:[self linkType]];
    [[self delegate] viewControllerSchemaAddLinkDidAdd:queryLink];
}

- (IBAction)cancel:(id)sender {
    [[self delegate] viewControllerSchemaAddLinkDidFinish: self];
}

#pragma mark - Delegate callbacks

- (void)tableViewControllerChooseFieldDidFinish: (MTQueryBuilderChooseFieldViewController *)controller
                                      withField: (RptqDatabaseSchemaField *)field {
    [[self navigationController] popToViewController: self animated: YES];
    
    RptqDatabaseSchemaTable *tableName = [field inTable];
    //NSString *fieldName = [field name];
    //NSString *tableFieldName = [[NSString stringWithFormat:@"%@.%@", tableName, fieldName] retain];
    NSString *tableFieldName = [[field toString] retain];
    switch ([self currentlyEditingPart]) {
        case MNSLinkLeft:
            [[[self tableViewCellTableFieldOne] detailTextLabel] setText: [tableFieldName lowercaseString]];
            [self setFirstTableName:tableName];
            [self setFirstFieldName:field];
            [self setFirstTableFieldName:tableFieldName];

            [[self tableViewCellTableFieldTwo] setUserInteractionEnabled:YES];
            [[[self tableViewCellTableFieldTwo] textLabel] setEnabled:YES];
            [[[self tableViewCellTableFieldTwo] detailTextLabel] setEnabled:YES];
            
            //[[[self tableViewCellTableFieldTwo] textLabel] setTextColor:[UIColor darkTextColor]];
            NSString *required = [NSLocalizedString(@"Required", @"Shows that this field is required.") lowercaseString];
            [[[self tableViewCellTableFieldTwo] detailTextLabel] setText: required];
            [[self tableViewCellTableFieldTwo] setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            break;
        case MNSLinkRight:
            [[[self tableViewCellTableFieldTwo] detailTextLabel] setText: [tableFieldName lowercaseString]];
            [self setSecondTableName:tableName];
            [self setSecondFieldName:field];
            [self setSecondTableFieldName:tableFieldName];
            break;
        default:
            break;
    }
    //NSLog(@"%@", NSStringFromCGRect([[self tableViewCellTableFieldOne] detailTextLabel].frame));
    //[[[self tableViewCellFieldOne] detailTextLabel] setNeedsLayout];
    [tableFieldName release];
}

- (void)viewControllerDidFinishWithTable:(RptqDatabaseSchemaTable *)result {
    [[self navigationController] popToViewController: self animated: YES];
    [[[self tableViewCellTableOne] detailTextLabel] setText: [[result name] lowercaseString]];
    [self setFirstTableName: result];
}

- (void)viewControllerSchemaAddLinkFirstFieldDidFinishWith:(RptqDatabaseSchemaField *)result {
    [[self navigationController] popToViewController: self animated: YES];
    [[[self tableViewCellFieldOne] detailTextLabel] setText: [[result name] lowercaseString]];
    [self setFirstFieldName: result];
}

- (void)viewControllerDidFinishWithSecondTable:(RptqDatabaseSchemaTable *)result {
    [[self navigationController] popToViewController: self animated: YES];
    [[[self tableViewCellTableTwo] detailTextLabel] setText: [[result name] lowercaseString]];
    [self setSecondTableName: result];
}

- (void)viewControllerSchemaAddLinkDidSecondFieldFinishWith:(RptqDatabaseSchemaField *)result {
    [[self navigationController] popToViewController: self animated: YES];
    [[[self tableViewCellFieldTwo] detailTextLabel] setText: [[result name] lowercaseString]];
    [self setSecondFieldName: result];
}

- (void)viewControllerSchemaAddLinkJoinTypeDidFinishWith:(MNSLinkType)result from:(MTManagedDocumentReport *)document {
    switch (result) {
        case MNSLinkTypeEquiJoin:
            [[[self tableViewCellJoinType] detailTextLabel] setText:[[MNSLinkTypeNames objectAtIndex:MNSLinkTypeEquiJoin] lowercaseString]];
            break;
        case MNSLinkTypeCrossJoin:
            [[[self tableViewCellJoinType] detailTextLabel] setText:[[MNSLinkTypeNames objectAtIndex:MNSLinkTypeCrossJoin] lowercaseString]];
            break;
        case MNSLinkTypeFullOuterJoin:
            [[[self tableViewCellJoinType] detailTextLabel] setText:[[MNSLinkTypeNames objectAtIndex:MNSLinkTypeFullOuterJoin] lowercaseString]];
            break;
        case MNSLinkTypeInnerJoin:
            [[[self tableViewCellJoinType] detailTextLabel] setText:[[MNSLinkTypeNames objectAtIndex:MNSLinkTypeInnerJoin] lowercaseString]];
            break;
        case MNSLinkTypeLeftOuterJoin:
            [[[self tableViewCellJoinType] detailTextLabel] setText:[[MNSLinkTypeNames objectAtIndex:MNSLinkTypeLeftOuterJoin] lowercaseString]];
            break;
        case MNSLinkTypeNaturalJoin:
            [[[self tableViewCellJoinType] detailTextLabel] setText:[[MNSLinkTypeNames objectAtIndex:MNSLinkTypeNaturalJoin] lowercaseString]];
            break;
        case MNSLinkTypeRightOuterJoin:
            [[[self tableViewCellJoinType] detailTextLabel] setText:[[MNSLinkTypeNames objectAtIndex:MNSLinkTypeRightOuterJoin] lowercaseString]];
            break;
        default:
            break;
    }
    [[self navigationController] popToViewController: self animated: YES];
    [self setLinkType: result];
}

@end