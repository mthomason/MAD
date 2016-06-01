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

#import <UIKit/UILabel.h>

#import <MAD/MADocument.h>
#import <MAD/MTDatabaseConnection.h>
#import <MAD/RptqUserCredentals+Extras.h>

#import <MAD/MADSQLJoinType.h>

@interface MTQueryBuilderAddLinkJoinTypeViewController ()

    @property (nonatomic, strong) IBOutlet UITableViewCell *tableViewCellEquiJoin;
    @property (nonatomic, strong) IBOutlet UITableViewCell *tableViewCellFullOuterJoin;
    @property (nonatomic, strong) IBOutlet UITableViewCell *tableViewCellNaturalJoin;

    @property (nonatomic, strong) IBOutlet UITableViewCell *tableViewCellCrossJoin;
    @property (nonatomic, strong) IBOutlet UITableViewCell *tableViewCellInnerJoin;
    @property (nonatomic, strong) IBOutlet UITableViewCell *tableViewCellLeftOuterJoin;
    @property (nonatomic, strong) IBOutlet UITableViewCell *tableViewCellRightOuterJoin;

@end

@implementation MTQueryBuilderAddLinkJoinTypeViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray <RptqUserCredentals *> *connections;
    connections = [RptqUserCredentals newArrayOfUserCredentalsForManagedObjectContext:self.document.managedObjectContext];
    RptqUserCredentals *userCredentals = connections[0];
    NSString *databaseDriverType = [userCredentals database_driver_type];

    if ([databaseDriverType isEqualToString:MADIdentifierDatabaseMySQL]) {

        [_tableViewCellEquiJoin setUserInteractionEnabled:YES];
        [_tableViewCellEquiJoin setSelectionStyle:UITableViewCellSelectionStyleGray];
        [[_tableViewCellEquiJoin textLabel] setEnabled:YES];
        [_tableViewCellNaturalJoin setUserInteractionEnabled:YES];
        [_tableViewCellNaturalJoin setSelectionStyle:UITableViewCellSelectionStyleGray];
        [[_tableViewCellNaturalJoin textLabel] setEnabled:YES];
        [_tableViewCellFullOuterJoin setUserInteractionEnabled:NO];
        [_tableViewCellFullOuterJoin setSelectionStyle:UITableViewCellSelectionStyleNone];
        [[_tableViewCellFullOuterJoin textLabel] setEnabled:NO];


        
    } else if ([databaseDriverType isEqualToString:MADIdentifierDatabaseTDS]) {
        
        [_tableViewCellEquiJoin setUserInteractionEnabled:YES];
        [_tableViewCellEquiJoin setSelectionStyle:UITableViewCellSelectionStyleGray];
        [[_tableViewCellEquiJoin textLabel] setEnabled:YES];
        [_tableViewCellNaturalJoin setUserInteractionEnabled:NO];
        [_tableViewCellNaturalJoin setSelectionStyle:UITableViewCellSelectionStyleNone];
        [[_tableViewCellNaturalJoin textLabel] setEnabled:NO];

    }

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self checkLinkType:[self.delegate initalLinktype]];
}

- (void)checkLinkType:(MNSLinkType)type {
    switch (type) {
        case MNSLinkTypeCrossJoin:
            
            _tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryCheckmark;
            _tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
            _tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            _tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
            _tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            _tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
            _tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;
            
            break;
        case MNSLinkTypeEquiJoin:
            
            _tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
            _tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryCheckmark;
            _tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            _tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
            _tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            _tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
            _tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;
            
            break;
        case MNSLinkTypeFullOuterJoin:
            
            _tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
            _tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
            _tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryCheckmark;
            _tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
            _tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            _tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
            _tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;

            break;
        case MNSLinkTypeInnerJoin:

            _tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
            _tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
            _tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            _tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryCheckmark;
            _tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            _tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
            _tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;

            break;
        case MNSLinkTypeLeftOuterJoin:
            
            _tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
            _tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
            _tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            _tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
            _tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryCheckmark;
            _tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
            _tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;

            break;
        case MNSLinkTypeNaturalJoin:
            
            _tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
            _tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
            _tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            _tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
            _tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            _tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryCheckmark;
            _tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;

            break;
        case MNSLinkTypeRightOuterJoin:
            
            _tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
            _tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
            _tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            _tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
            _tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            _tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
            _tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryCheckmark;

            break;
        default:
            
            _tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
            _tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
            _tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            _tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
            _tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
            _tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
            _tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;
            
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
                                                                   from: self.document];
    }

}

@end
