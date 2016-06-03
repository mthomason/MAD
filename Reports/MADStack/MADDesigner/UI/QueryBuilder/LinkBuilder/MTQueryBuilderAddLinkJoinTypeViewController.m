//
//  UIViewControllerSchemaAddLink.m
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryBuilderAddLinkJoinTypeViewController.h"
#import "MADQueryBuilderAddLinkJoinTypeDelegate.h"

#import <UIKit/UILabel.h>

#import <MAD/MADocument.h>
#import <MAD/MTDatabaseConnection.h>
#import <MAD/RptqUserCredentals+Extras.h>

#import <MAD/MADSQLJoinType.h>

@interface MTQueryBuilderAddLinkJoinTypeViewController ()

    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellEquiJoin;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellFullOuterJoin;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellNaturalJoin;

    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellCrossJoin;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellInnerJoin;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellLeftOuterJoin;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellRightOuterJoin;

@end

@implementation MTQueryBuilderAddLinkJoinTypeViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray <RptqUserCredentals *> *connections;
    connections = [RptqUserCredentals newArrayOfUserCredentalsForManagedObjectContext:self.document.managedObjectContext];
    RptqUserCredentals *userCredentals = connections[0];
    NSString *databaseDriverType = userCredentals.database_driver_type;

    UITableViewCell *tableViewCell;
    if ([databaseDriverType isEqualToString:MADIdentifierDatabaseMySQL]) {

        tableViewCell = _tableViewCellEquiJoin;
        tableViewCell.userInteractionEnabled = YES;
        tableViewCell.selectionStyle = UITableViewCellSelectionStyleGray;
        tableViewCell.textLabel.enabled = YES;
        
        tableViewCell = _tableViewCellNaturalJoin;
        tableViewCell.userInteractionEnabled = YES;
        tableViewCell.selectionStyle = UITableViewCellSelectionStyleGray;
        tableViewCell.textLabel.enabled = YES;

        tableViewCell = _tableViewCellFullOuterJoin;
        tableViewCell.userInteractionEnabled = NO;
        tableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
        tableViewCell.textLabel.enabled = NO;


        
    } else if ([databaseDriverType isEqualToString:MADIdentifierDatabaseTDS]) {

        tableViewCell = _tableViewCellEquiJoin;
        [tableViewCell setUserInteractionEnabled:YES];
        tableViewCell.selectionStyle = UITableViewCellSelectionStyleGray;
        [tableViewCell.textLabel setEnabled:YES];

        tableViewCell = _tableViewCellNaturalJoin;
        tableViewCell.userInteractionEnabled = NO;
        tableViewCell.selectionStyle = UITableViewCellSelectionStyleGray;
        tableViewCell.textLabel.enabled = NO;
        
    }

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self checkLinkType:[self.delegate initalLinktype]];
}

- (void)checkLinkType:(MNSLinkType)type {

    UITableViewCell *tableViewCellCrossJoin         = _tableViewCellCrossJoin;
    UITableViewCell *tableViewCellEquiJoin          = _tableViewCellEquiJoin;
    UITableViewCell *tableViewCellFullOuterJoin     = _tableViewCellFullOuterJoin;
    UITableViewCell *tableViewCellInnerJoin         = _tableViewCellInnerJoin;
    UITableViewCell *tableViewCellLeftOuterJoin     = _tableViewCellLeftOuterJoin;
    UITableViewCell *tableViewCellNaturalJoin       = _tableViewCellNaturalJoin;
    UITableViewCell *tableViewCellRightOuterJoin    = _tableViewCellRightOuterJoin;
    
    switch (type) {
        case MNSLinkTypeCrossJoin:
            
            tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryCheckmark;
            tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
            tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
            tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
            tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;
            
            break;
        case MNSLinkTypeEquiJoin:
            
            tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
            tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryCheckmark;
            tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
            tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
            tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;
            
            break;
        case MNSLinkTypeFullOuterJoin:
            
            tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
            tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
            tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryCheckmark;
            tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
            tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
            tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;

            break;
        case MNSLinkTypeInnerJoin:

            tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
            tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
            tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryCheckmark;
            tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
            tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;

            break;
        case MNSLinkTypeLeftOuterJoin:
            
            tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
            tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
            tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
            tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryCheckmark;
            tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
            tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;

            break;
        case MNSLinkTypeNaturalJoin:
            
            tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
            tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
            tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
            tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryCheckmark;
            tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;

            break;
        case MNSLinkTypeRightOuterJoin:
            
            tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
            tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
            tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
            tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
            tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryCheckmark;

            break;
        default:
            
            tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
            tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
            tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
            tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
            tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;
            
            break;
    }
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    MNSLinkType linktype = MNSLinkTypeUnknown;
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell.reuseIdentifier isEqualToString:MNSJoinTypeInnerJoin]) {
        linktype = MNSLinkTypeInnerJoin;
        
    } else if ([cell.reuseIdentifier isEqualToString:MNSJoinTypeEquiJoin]) {
        linktype = MNSLinkTypeEquiJoin;

    } else if ([cell.reuseIdentifier isEqualToString:MNSJoinTypeNaturalJoin]) {
        linktype = MNSLinkTypeNaturalJoin;
    
    } else if ([cell.reuseIdentifier isEqualToString:MNSJoinTypeCrossJoin]) {
        linktype = MNSLinkTypeCrossJoin;
    
    } else if ([cell.reuseIdentifier isEqualToString:MNSJoinTypeLeftOuterJoin]) {
        linktype = MNSLinkTypeLeftOuterJoin;

    } else if ([cell.reuseIdentifier isEqualToString:MNSJoinTypeRightOuterJoin]) {
        linktype = MNSLinkTypeRightOuterJoin;
    
    } else if ([cell.reuseIdentifier isEqualToString:MNSJoinTypeFullOuterJoin]) {
        linktype = MNSLinkTypeFullOuterJoin;
    }
    
    if ((NSInteger)linktype != MNSLinkTypeUnknown) {
        [self checkLinkType:linktype];
        [self.delegate viewControllerSchemaAddLinkJoinTypeDidFinishWith: linktype
                                                                   from: _document];
    }

}

@end
