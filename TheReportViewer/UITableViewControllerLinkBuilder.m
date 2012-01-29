//
//  UITableViewControllerLinkBuilder.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/26/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewControllerLinkBuilder.h"
#import "RptqTable.h"
#import "RptqField.h"
#import "RptqQueryTables.h"
#import "RptqQueryFields.h"

@implementation UITableViewControllerLinkBuilder

@synthesize delegate = _delegate;
@synthesize tableViewCellJoinType = _tableViewCellJoinType;
@synthesize tableViewCellTableOne = _tableViewCellTableOne;
@synthesize tableViewCellFieldOne = _tableViewCellFieldOne;
@synthesize tableViewCellTableTwo = _tableViewCellTableTwo;
@synthesize tableViewCellFieldTwo = _tableViewCellFieldTwo;
@synthesize managedDocumentQuery = _managedDocumentQuery;
@synthesize linkType = _linkType;
@synthesize firstTableName = _firstTableName, firstFieldName = _firstFieldName, secondTableName = _secondTableName, secondFieldName = _secondFieldName;

- (void)dealloc {
    [_firstTableName release];
    [_firstFieldName release];
    [_secondTableName release];
    [_managedDocumentQuery release];
    [_tableViewCellJoinType release];
    [_tableViewCellTableOne release];
    [_tableViewCellFieldOne release];
    [_tableViewCellTableTwo release];
    [_tableViewCellFieldTwo release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidUnload {
    [self setTableViewCellJoinType:nil];
    [self setTableViewCellTableOne:nil];
    [self setTableViewCellFieldOne:nil];
    [self setTableViewCellTableTwo:nil];
    [self setTableViewCellFieldTwo:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showSelectJoinType"]) {
        NSLog(@"Class: %@", NSStringFromClass([[segue destinationViewController] class]));
        
        if ([[segue destinationViewController] isKindOfClass: [UIViewControllerSchemaAddLinkJoinType class]]) {
            UIViewControllerSchemaAddLinkJoinType *vcFf = [segue destinationViewController];
            if (vcFf) {
                [vcFf setManagedDocumentQuery: [self managedDocumentQuery]];
                [vcFf setDelegate: self];

            }
        }

    } else {
        
        if ([[segue identifier] isEqualToString:@"showSelectTableOne"]) {
            NSLog(@"Class: %@", NSStringFromClass([[segue destinationViewController] class]));
            if ([[segue destinationViewController] isKindOfClass: [UIViewControllerSchemaAddLinkFirstTable class]]) {
                UIViewControllerSchemaAddLinkFirstTable *tvc = [segue destinationViewController];
                if (tvc) {
                    [tvc setDelegate:self];
                    [tvc setManagedDocumentQuery: [self managedDocumentQuery]];
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryTables class])];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES];
                    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                    NSLog(@"[[tvc managedDocumentQuery] managedObjectContext]: %@", [[self managedDocumentQuery] managedObjectContext]);
                    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                          managedObjectContext: [[tvc managedDocumentQuery] managedObjectContext]
                                                                                            sectionNameKeyPath: nil
                                                                                                     cacheName: nil];
                    [tvc setFetchedResultsController: frc];
                    [frc release];
                }
            }
        } else if ([[segue identifier] isEqualToString:@"showSelectFieldOne"]) {
            NSLog(@"Class: %@", NSStringFromClass([[segue destinationViewController] class]));
            if ([[segue destinationViewController] isKindOfClass: [UIViewControllerSchemaAddLinkFirstField class]]) {
                UIViewControllerSchemaAddLinkFirstField *vcFf = [segue destinationViewController];
                if (vcFf) {
                    [vcFf setDelegate:self];
                    [vcFf setManagedDocumentQuery: [self managedDocumentQuery]];
                    
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqField class])];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES];
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable.name == %@", [self firstTableName]];
                    request.predicate = predicate;
                    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                          managedObjectContext: [[vcFf managedDocumentQuery] managedObjectContext]
                                                                                            sectionNameKeyPath: nil
                                                                                                     cacheName: nil];
                    [vcFf setFetchedResultsController: frc];
                    [frc release];
                }
            }
        } else if ([[segue identifier] isEqualToString:@"showSelectTableTwo"]) {
            NSLog(@"Class: %@", NSStringFromClass([[segue destinationViewController] class]));
            if ([[segue destinationViewController] isKindOfClass: [UIViewControllerSchemaAddLinkSecondTable class]]) {
                UIViewControllerSchemaAddLinkSecondTable *vcFf = [segue destinationViewController];
                if (vcFf) {                
                    [vcFf setDelegate:self];
                    [vcFf setManagedDocumentQuery: [self managedDocumentQuery]];
                    
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryTables class])];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES];
                    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name != %@", [self firstTableName]];
                    [request setPredicate: predicate];
                    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                          managedObjectContext: [[vcFf managedDocumentQuery] managedObjectContext]
                                                                                            sectionNameKeyPath: nil
                                                                                                     cacheName: nil];
                    [vcFf setFetchedResultsController: frc];
                    [frc release];
                }
            }
        } else if ([[segue identifier] isEqualToString:@"showSelectFieldTwo"]) {
            NSLog(@"Class: %@", NSStringFromClass([[segue destinationViewController] class]));
            if ([[segue destinationViewController] isKindOfClass: [UIViewControllerSchemaAddLinkSecondField class]]) {
                UIViewControllerSchemaAddLinkSecondField *vcFf = [segue destinationViewController];
                if (vcFf) {                
                    [vcFf setDelegate:self];
                    [vcFf setManagedDocumentQuery: [self managedDocumentQuery]];
                    
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqField class])];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES];
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable.name == %@", [self secondTableName]];
                    request.predicate = predicate;
                    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                          managedObjectContext: [[vcFf managedDocumentQuery] managedObjectContext]
                                                                                            sectionNameKeyPath: nil
                                                                                                     cacheName: nil];
                    [vcFf setFetchedResultsController: frc];
                    [frc release];
                }
            }
        }
    }
}


#pragma mark - Actions

- (IBAction)done:(id)sender {
    
}

- (IBAction)save:(id)sender {
    [[self delegate] viewControllerSchemaAddLinkDidSelectFirstTableName:[self firstTableName]
                                                         firstFieldName:[self firstFieldName]
                                                        secondTableName:[self secondTableName]
                                                        secondFieldName:[self secondFieldName]
                                                           withJoinType:[self linkType]];
}

- (IBAction)cancel:(id)sender {
    [[self delegate] viewControllerSchemaAddLinkDidFinish: self];
}

#pragma mark - Delegate callbacks

- (void)viewControllerSchemaAddLinkDidFinishWith:(NSString *)result from:(UIManagedDocumentQuery *)document {
    [[self navigationController] popToViewController: self animated: YES];
    [[[self tableViewCellTableOne] detailTextLabel] setText: [result lowercaseString]];
    [self setManagedDocumentQuery: document];
    [self setFirstTableName: result];
}

- (void)viewControllerSchemaAddLinkFirstFieldDidFinishWith:(NSString *)result from:(UIManagedDocumentQuery *)document {
    [[self navigationController] popToViewController: self animated: YES];
    [[[self tableViewCellFieldOne] detailTextLabel] setText: [result lowercaseString]];
    [self setManagedDocumentQuery: document];
    [self setFirstFieldName: result];
}

- (void)viewControllerSchemaAddLinkSecondTableDidFinishWith:(NSString *)result from:(UIManagedDocumentQuery *)document {
    [[self navigationController] popToViewController: self animated: YES];
    [[[self tableViewCellTableTwo] detailTextLabel] setText: [result lowercaseString]];
    [self setManagedDocumentQuery: document];
    [self setSecondTableName: result];
}

- (void)viewControllerSchemaAddLinkDidSecondFieldFinishWith:(NSString *)result from:(UIManagedDocumentQuery *)document {
    [[self navigationController] popToViewController: self animated: YES];
    [[[self tableViewCellFieldTwo] detailTextLabel] setText: [result lowercaseString]];
    [self setManagedDocumentQuery: document];
    [self setSecondFieldName: result];
}

- (void)viewControllerSchemaAddLinkJoinTypeDidFinishWith:(MNSLinkType)result from:(UIManagedDocumentQuery *)document {
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
    [self setManagedDocumentQuery: document];
    [self setLinkType: result];
}

@end