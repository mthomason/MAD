//
//  UIViewControllerSchemaAddLink.m
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryAddLinkJoinTypeController.h"

#import <UIKit/UILabel.h>

#import "MADQueryBuilderAddLinkJoinTypeDelegate.h"

#import <MAD/MADocument.h>
#import <MAD/MADDatabaseConnection.h>
#import <MAD/RptqDatabaseCredentals+Extras.h>

#import <MAD/MADSQLJoinType.h>

#import <MAD/MADDatabaseConnection.h>

@interface MADQueryAddLinkJoinTypeController ()

    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellEquiJoin;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellFullOuterJoin;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellNaturalJoin;

    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellCrossJoin;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellInnerJoin;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellLeftOuterJoin;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellRightOuterJoin;

@end

@implementation MADQueryAddLinkJoinTypeController

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray <RptqDatabaseCredentals *> *connections;
    connections = [RptqDatabaseCredentals newDatabaseCredentals:self.document.managedObjectContext];
    RptqDatabaseCredentals *userCredentals = connections[0];
    NSString *databaseDriverType = userCredentals.driverID;

    UITableViewCell *tableViewCell;
    if ([databaseDriverType isEqualToString:[MADDatabaseConnection Identifier:MADDatabaseTypeMySQL]]) {

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


        
    } else if ([databaseDriverType isEqualToString:[MADDatabaseConnection Identifier:MADDatabaseTypeTDS]]) {

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

    switch (type) {
        case MNSLinkTypeCrossJoin:
            
            self.tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryCheckmark;
            self.tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
            self.tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            self.tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
            self.tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            self.tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
            self.tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;
            
            break;
        case MNSLinkTypeEquiJoin:
            
            self.tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
            self.tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryCheckmark;
            self.tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            self.tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
            self.tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            self.tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
            self.tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;
            
            break;
        case MNSLinkTypeFullOuterJoin:
            
            self.tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
            self.tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
            self.tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryCheckmark;
            self.tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
            self.tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            self.tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
            self.tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;

            break;
        case MNSLinkTypeInnerJoin:

            self.tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
            self.tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
            self.tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            self.tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryCheckmark;
            self.tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            self.tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
            self.tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;

            break;
        case MNSLinkTypeLeftOuterJoin:
            
            self.tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
            self.tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
            self.tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            self.tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
            self.tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryCheckmark;
            self.tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
            self.tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;

            break;
        case MNSLinkTypeNaturalJoin:
            
            self.tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
            self.tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
            self.tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            self.tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
            self.tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            self.tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryCheckmark;
            self.tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;

            break;
        case MNSLinkTypeRightOuterJoin:
            
            self.tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
            self.tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
            self.tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            self.tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
            self.tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            self.tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
            self.tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryCheckmark;

            break;
        default:
            
            self.tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
            self.tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
            self.tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            self.tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
            self.tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            self.tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
            self.tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;
            
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
        [self.delegate viewController:self addLinkJoinType: linktype];
    }

}

@end
