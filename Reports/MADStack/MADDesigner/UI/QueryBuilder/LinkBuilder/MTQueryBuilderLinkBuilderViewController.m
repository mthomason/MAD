//
//  UITableViewControllerLinkBuilder.m
//  Reports
//
//  Created by Michael Thomason on 1/26/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryBuilderLinkBuilderViewController.h"

#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UILabel.h>

#import <MAD/MADocument.h>

#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqQueryLinks+Extras.h>

#import "MTQueryBuilderChooseFieldViewController.h"
#import "MTQueryBuilderAddLinkJoinTypeViewController.h"

@interface MTQueryBuilderLinkBuilderViewController ()

    @property (nonatomic, strong) RptqQueryTable *firstTable;
    @property (nonatomic, strong) RptqQueryTable *secondTable;

    @property (nonatomic, strong) RptqQueryField *firstField;
    @property (nonatomic, strong) RptqQueryField *secondField;

    @property (nonatomic, strong) IBOutlet UILabel *labelRightField;

@end

@implementation MTQueryBuilderLinkBuilderViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    return self = [super initWithCoder:aDecoder];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setJoinType:MNSLinkTypeLeftOuterJoin];
    self.currentlyEditingPart = MADLinkNone;
    [self updateRightLabelState];
    [self updateSaveButtonState];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"showSelectJoinType"]) {

        if ([segue.destinationViewController isKindOfClass:
                                        [MTQueryBuilderAddLinkJoinTypeViewController class]]) {
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

- (void)setupJoinController:(MTQueryBuilderAddLinkJoinTypeViewController *)controller {
    controller.delegate = self;
    controller.document = self.document;
}

- (void)setupFieldController1:(MTQueryBuilderChooseFieldViewController *)controller {
    [self setupFieldController:controller excludeTable:self.firstTable];
}

- (void)setupFieldController2:(MTQueryBuilderChooseFieldViewController *)controller {
    [self setupFieldController:controller excludeTable:self.secondTable];
}

- (void)setupFieldController:(MTQueryBuilderChooseFieldViewController *)controller
                 excludeTable:(RptqQueryTable *)excludeTable {
    if (controller == nil) return;
    id alias = excludeTable.alias.copy;
    NSArray *excludeTables = alias != nil ?
                                [[NSArray alloc] initWithObjects:alias, nil] :
                                [[NSArray alloc] init];
    controller.excludeTables = excludeTables;
    controller.delegate = self;
    controller.document = self.document;
}

#pragma mark - Actions

- (IBAction)save:(id)sender {
    if (self.firstField && self.secondField) {
        RptqQueryLinks *links;
        links = [RptqQueryLinks newQueryLinksWithLeftField: self.firstField
                                                rightField: self.secondField
                                                  joinType: self.linkType
                                      managedObjectContext: self.document.managedObjectContext];
        [self.queryLinkDelegate viewControllerSchemaAddLinkDidAdd: links];
    } else {
        [self cancel:sender];
    }
}

- (IBAction)cancel:(id)sender {
    [self.queryLinkDelegate viewControllerDidCancel:self];
}

#pragma mark - Delegate callbacks

- (MNSLinkType)initalLinktype {
    return self.linkType;
}

- (void)tableViewControllerChooseFieldDidFinish: (MTQueryBuilderChooseFieldViewController *)controller
                                      withField: (RptqQueryField *)queryField {
    [self.navigationController popToViewController: self animated: YES];
    
    RptqQueryTable *queryTable = queryField.inQueryTable;
    NSString *tableFieldName = [queryField toString];
    switch (self.currentlyEditingPart) {
        case MADLinkLeft: {

            self.tableViewCellTableFieldOne.detailTextLabel.text = tableFieldName.lowercaseString;
            self.firstTable = queryTable;
            self.firstField = queryField;
            
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
            self.tableViewCellTableFieldTwo.detailTextLabel.text = tableFieldName.lowercaseString;
            self.secondTable = queryTable;
            self.secondField = queryField;
            break;
        }
        default:
            break;
    }
    [self updateSaveButtonState];
}

- (void)viewControllerSchemaAddLinkJoinTypeDidFinishWith:(MNSLinkType)result from:(MADocument *)document {
    [self setJoinType:result];
    [self.navigationController popToViewController: self animated: YES];
}

#pragma mark - Helper functions

- (void)setJoinType:(MNSLinkType)type {
    NSString *linkName = [RptqQueryLinks newLocalizedNameForLinkType:type];
    NSString *text = linkName.lowercaseString;
    self.tableViewCellJoinType.detailTextLabel.text = text;
    self.linkType = type;
}

- (BOOL)firstFieldSet {
    return self.firstField != nil;
}

- (BOOL)secondFieldSet {
    return self.secondField != nil && [self.firstField isEqual:self.secondField] == NO;
}

- (void)updateRightLabelState {

    BOOL enabled = [self firstFieldSet];
    self.tableViewCellTableFieldTwo.userInteractionEnabled = enabled;
    self.tableViewCellTableFieldTwo.textLabel.enabled = enabled;
    self.tableViewCellTableFieldTwo.detailTextLabel.enabled = enabled;
    self.labelRightField.enabled = enabled;
    
    UIColor *darkTextColor = enabled ? [UIColor blackColor] : [UIColor darkTextColor];
    self.labelRightField.textColor = darkTextColor;
}

- (void)updateSaveButtonState {
    BOOL enabled = [self firstFieldSet] && self.secondField;
    self.navigationItem.rightBarButtonItem.enabled = enabled;
}

@end
