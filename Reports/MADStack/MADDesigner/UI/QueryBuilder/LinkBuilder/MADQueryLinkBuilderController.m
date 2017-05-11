//
//  UITableViewControllerLinkBuilder.m
//  Reports
//
//  Created by Michael Thomason on 1/26/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryLinkBuilderController.h"

#import <CoreData/NSManagedObjectContext.h>

#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UILabel.h>

#import <MAD/MADocument.h>

#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>

#import <MAD/RptqQueryTable.h>

#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryField+Extras.h>

#import <MAD/RptqQueryLinks.h>
#import <MAD/RptqQueryLinks+Extras.h>

#import "MADQueryChooseFieldController.h"
#import "MADQueryAddLinkJoinTypeController.h"

@interface MADQueryLinkBuilderController ()

    @property (nonatomic, strong) NSManagedObjectID /* RptqQueryTable */ *firstTableID;
    @property (nonatomic, strong) NSManagedObjectID /* RptqQueryTable */ *secondTableID;

    @property (nonatomic, strong) NSManagedObjectID /* RptqQueryField */ *firstFieldID;
    @property (nonatomic, strong) NSManagedObjectID /* RptqQueryField */ *secondFieldID;

    @property (nonatomic, strong) IBOutlet UILabel *labelRightField;

@end

@implementation MADQueryLinkBuilderController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    return self = [super initWithCoder:aDecoder];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setJoinType:MADLinkTypeLeftOuterJoin];
    self.currentlyEditingPart = MADLinkNone;
    [self updateRightLabelState];
    [self updateSaveButtonState];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"showSelectJoinType"]) {

        if ([segue.destinationViewController isKindOfClass:
                                        [MADQueryAddLinkJoinTypeController class]]) {
            [self setupJoinController:segue.destinationViewController];
        }
        
    } else {
        
        if ([segue.identifier isEqualToString:@"showSelectLinkTableFieldOne"]) {
            
            self.currentlyEditingPart = MADLinkLeft;
            [self setupFieldController2:segue.destinationViewController];

        } else if ([segue.identifier isEqualToString:@"showSelectLinkTableFieldTwo"]) {
            
            self.currentlyEditingPart = MADLinkRight;
            [self setupFieldController1:segue.destinationViewController];
            
        }
    }
}

- (void)setupJoinController:(MADQueryAddLinkJoinTypeController *)controller {
    controller.delegate = self;
    controller.document = self.document;
}

- (void)setupFieldController1:(MADQueryChooseFieldController *)controller {
    [self setupFieldController:controller excludeTable:self.firstTableID];
}

- (void)setupFieldController2:(MADQueryChooseFieldController *)controller {
    [self setupFieldController:controller excludeTable:self.secondTableID];
}

- (void)setupFieldController:(MADQueryChooseFieldController *)controller
                excludeTable:(NSManagedObjectID *)excludeTableID {
    if (controller == nil) return;
    
    MADocument *document = self.document;
    controller.delegate = self;
    controller.document = document;

    if (excludeTableID != nil) {
        NSManagedObjectContext *moc = document.managedObjectContext;
        RptqQueryTable *excludeTable = [moc objectWithID:excludeTableID];
        id alias = excludeTable.alias.copy;
        NSArray *excludeTables = alias != nil ?
                                [[NSArray alloc] initWithObjects:alias, nil] :
                                [[NSArray alloc] init];
        controller.excludeTables = excludeTables;
    } else {
        NSArray *excludeTables = [[NSArray alloc] init];
        controller.excludeTables = excludeTables;
    }
    
}

#pragma mark - Actions

- (IBAction)save:(id)sender {
    if (self.firstFieldID && self.secondFieldID) {
        
        id <MTQueryBuilderLinkBuilderDelegate, MADViewControllerStandardProtocol> queryLinkDelegate;
        queryLinkDelegate = self.queryLinkDelegate;
        
        MADocument *document = self.document;
        NSManagedObjectContext *managedObjectContext = document.managedObjectContext;
        
        
        
        RptqQueryLinks *link;
        RptqQueryField *firstField = [managedObjectContext objectWithID:self.firstFieldID];
        RptqQueryField *secondField = [managedObjectContext objectWithID:self.secondFieldID];
        link = [RptqQueryLinks newQueryLinksWithLeftField: firstField
                                               rightField: secondField
                                                 joinType: self.linkType
                                     managedObjectContext: managedObjectContext];
        [document.activeDocumentModel addQueryLink: link];
        [document saveContext];

        [queryLinkDelegate viewController: self addedQueryLink: link.objectID];
    } else {
        [self cancel: sender];
    }
}

- (IBAction)cancel:(id)sender {
    [self.queryLinkDelegate viewControllerDidCancel:self];
}

#pragma mark - Delegate callbacks

- (MADLinkType)initalLinktype {
    return self.linkType;
}

- (void)tableViewControllerChooseFieldDidFinish: (MADQueryChooseFieldController *)controller
                                    withFieldID: (NSManagedObjectID *)fieldID {
    
    NSManagedObjectContext *context = self.document.managedObjectContext;
    RptqQueryField *queryField = [context objectWithID: fieldID];
    
    [self.navigationController popToViewController: self animated: YES];
    
    RptqQueryTable *queryTable = queryField.inQueryTable;
    NSString *tableFieldName = [queryField toString];
    switch (self.currentlyEditingPart) {
        case MADLinkLeft: {

            self.tableViewCellTableFieldOne.detailTextLabel.text = tableFieldName.localizedLowercaseString;
            self.firstTableID = queryTable.objectID;
            self.firstFieldID = queryField.objectID;
            
            [self updateRightLabelState];

            NSString *required = NSLocalizedString(@"Required",
                                                   @"Shows that this field is required.");
            required = required.lowercaseString;
            self.tableViewCellTableFieldTwo.detailTextLabel.text = required;
            self.tableViewCellTableFieldTwo.accessoryType =
                                                    UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case MADLinkRight: {
            self.tableViewCellTableFieldTwo.detailTextLabel.text = tableFieldName.localizedLowercaseString;
            self.secondTableID = queryTable.objectID;
            self.secondFieldID = queryField.objectID;
            break;
        }
        default:
            break;
    }
    [self updateSaveButtonState];
}

- (void)viewController:(UIViewController *)viewController addLinkJoinType:(MADLinkType)result {
    [self setJoinType:result];
    [self.navigationController popToViewController: self animated: YES];
}

#pragma mark - Helper functions

- (void)setJoinType:(MADLinkType)type {
    NSString *linkName = [RptqQueryLinks newLocalizedNameForLinkType:type];
    self.tableViewCellJoinType.detailTextLabel.text = linkName.lowercaseString;
    self.linkType = type;
}

- (BOOL)firstFieldSet {
    return self.firstFieldID != nil;
}

- (BOOL)secondFieldSet {
    return self.secondFieldID != nil && [self.firstFieldID isEqual:self.secondFieldID] == NO;
}

- (void)updateRightLabelState {

    BOOL enabled = [self firstFieldSet];
    self.tableViewCellTableFieldTwo.userInteractionEnabled = enabled;
    self.tableViewCellTableFieldTwo.textLabel.enabled = enabled;
    self.tableViewCellTableFieldTwo.detailTextLabel.enabled = enabled;
    self.labelRightField.enabled = enabled;
    self.labelRightField.textColor = enabled ? [UIColor blackColor] : [UIColor darkTextColor];
}

- (void)updateSaveButtonState {
    BOOL enabled = [self firstFieldSet] && self.secondFieldID;
    self.navigationItem.rightBarButtonItem.enabled = enabled;
}

@end
