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
#import "AppDelegate.h"
#import "MTApplicationInstance.h"
#import "RptqUserCredentals.h"
#import "RptqUserCredentals+Extras.h"
#import "RptqQueryLinks.h"
#import "RptqQueryLinks+Extras.h"
#import "MTDatabaseMySql.h"
#import "MTDatabaseSqlServer.h"

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
    
    NSArray *connections = [RptqUserCredentals userCredentalsForManagedObjectContext:self.document.managedObjectContext];
    RptqUserCredentals *userCredentals = connections[0];
    NSString *databaseDriverType = [userCredentals database_driver_type];

    if ([databaseDriverType isEqualToString:[MTDatabaseMySql identifier]]) {

        [[self tableViewCellEquiJoin] setUserInteractionEnabled:YES];
        [[self tableViewCellEquiJoin] setSelectionStyle:UITableViewCellSelectionStyleGray];
        [[[self tableViewCellEquiJoin] textLabel] setEnabled:YES];
        [[self tableViewCellNaturalJoin] setUserInteractionEnabled:YES];
        [[self tableViewCellNaturalJoin] setSelectionStyle:UITableViewCellSelectionStyleGray];
        [[[self tableViewCellNaturalJoin] textLabel] setEnabled:YES];
        [[self tableViewCellFullOuterJoin] setUserInteractionEnabled:NO];
        [[self tableViewCellFullOuterJoin] setSelectionStyle:UITableViewCellSelectionStyleNone];
        [[[self tableViewCellFullOuterJoin] textLabel] setEnabled:NO];


        
    } else if ([databaseDriverType isEqualToString:[MTDatabaseSqlServer identifier]]) {
        
        [[self tableViewCellEquiJoin] setUserInteractionEnabled:YES];
        [[self tableViewCellEquiJoin] setSelectionStyle:UITableViewCellSelectionStyleGray];
        [[[self tableViewCellEquiJoin] textLabel] setEnabled:YES];
        [[self tableViewCellNaturalJoin] setUserInteractionEnabled:NO];
        [[self tableViewCellNaturalJoin] setSelectionStyle:UITableViewCellSelectionStyleNone];
        [[[self tableViewCellNaturalJoin] textLabel] setEnabled:NO];

    }

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self checkLinkType:[self.delegate initalLinktype]];
}

- (void)checkLinkType:(MNSLinkType)type {
    switch (type) {
        case MNSLinkTypeCrossJoin:
            
            [[self tableViewCellCrossJoin] setAccessoryType:        UITableViewCellAccessoryCheckmark];
            [[self tableViewCellEquiJoin] setAccessoryType:         UITableViewCellAccessoryNone];
            [[self tableViewCellFullOuterJoin] setAccessoryType:    UITableViewCellAccessoryNone];
            [[self tableViewCellInnerJoin] setAccessoryType:        UITableViewCellAccessoryNone];
            [[self tableViewCellLeftOuterJoin] setAccessoryType:    UITableViewCellAccessoryNone];
            [[self tableViewCellNaturalJoin] setAccessoryType:      UITableViewCellAccessoryNone];
            [[self tableViewCellRightOuterJoin] setAccessoryType:   UITableViewCellAccessoryNone];
            
            break;
        case MNSLinkTypeEquiJoin:
            
            [[self tableViewCellCrossJoin] setAccessoryType:        UITableViewCellAccessoryNone];
            [[self tableViewCellEquiJoin] setAccessoryType:         UITableViewCellAccessoryCheckmark];
            [[self tableViewCellFullOuterJoin] setAccessoryType:    UITableViewCellAccessoryNone];
            [[self tableViewCellInnerJoin] setAccessoryType:        UITableViewCellAccessoryNone];
            [[self tableViewCellLeftOuterJoin] setAccessoryType:    UITableViewCellAccessoryNone];
            [[self tableViewCellNaturalJoin] setAccessoryType:      UITableViewCellAccessoryNone];
            [[self tableViewCellRightOuterJoin] setAccessoryType:   UITableViewCellAccessoryNone];
            
            break;
        case MNSLinkTypeFullOuterJoin:
            
            [[self tableViewCellCrossJoin] setAccessoryType:        UITableViewCellAccessoryNone];
            [[self tableViewCellEquiJoin] setAccessoryType:         UITableViewCellAccessoryNone];
            [[self tableViewCellFullOuterJoin] setAccessoryType:    UITableViewCellAccessoryCheckmark];
            [[self tableViewCellInnerJoin] setAccessoryType:        UITableViewCellAccessoryNone];
            [[self tableViewCellLeftOuterJoin] setAccessoryType:    UITableViewCellAccessoryNone];
            [[self tableViewCellNaturalJoin] setAccessoryType:      UITableViewCellAccessoryNone];
            [[self tableViewCellRightOuterJoin] setAccessoryType:   UITableViewCellAccessoryNone];

            break;
        case MNSLinkTypeInnerJoin:

            [[self tableViewCellCrossJoin] setAccessoryType:        UITableViewCellAccessoryNone];
            [[self tableViewCellEquiJoin] setAccessoryType:         UITableViewCellAccessoryNone];
            [[self tableViewCellFullOuterJoin] setAccessoryType:    UITableViewCellAccessoryNone];
            [[self tableViewCellInnerJoin] setAccessoryType:        UITableViewCellAccessoryCheckmark];
            [[self tableViewCellLeftOuterJoin] setAccessoryType:    UITableViewCellAccessoryNone];
            [[self tableViewCellNaturalJoin] setAccessoryType:      UITableViewCellAccessoryNone];
            [[self tableViewCellRightOuterJoin] setAccessoryType:   UITableViewCellAccessoryNone];

            break;
        case MNSLinkTypeLeftOuterJoin:
            
            [[self tableViewCellCrossJoin] setAccessoryType:        UITableViewCellAccessoryNone];
            [[self tableViewCellEquiJoin] setAccessoryType:         UITableViewCellAccessoryNone];
            [[self tableViewCellFullOuterJoin] setAccessoryType:    UITableViewCellAccessoryNone];
            [[self tableViewCellInnerJoin] setAccessoryType:        UITableViewCellAccessoryNone];
            [[self tableViewCellLeftOuterJoin] setAccessoryType:    UITableViewCellAccessoryCheckmark];
            [[self tableViewCellNaturalJoin] setAccessoryType:      UITableViewCellAccessoryNone];
            [[self tableViewCellRightOuterJoin] setAccessoryType:   UITableViewCellAccessoryNone];

            break;
        case MNSLinkTypeNaturalJoin:
            
            [[self tableViewCellCrossJoin] setAccessoryType:        UITableViewCellAccessoryNone];
            [[self tableViewCellEquiJoin] setAccessoryType:         UITableViewCellAccessoryNone];
            [[self tableViewCellFullOuterJoin] setAccessoryType:    UITableViewCellAccessoryNone];
            [[self tableViewCellInnerJoin] setAccessoryType:        UITableViewCellAccessoryNone];
            [[self tableViewCellLeftOuterJoin] setAccessoryType:    UITableViewCellAccessoryNone];
            [[self tableViewCellNaturalJoin] setAccessoryType:      UITableViewCellAccessoryCheckmark];
            [[self tableViewCellRightOuterJoin] setAccessoryType:   UITableViewCellAccessoryNone];

            break;
        case MNSLinkTypeRightOuterJoin:
            
            [[self tableViewCellCrossJoin] setAccessoryType:        UITableViewCellAccessoryNone];
            [[self tableViewCellEquiJoin] setAccessoryType:         UITableViewCellAccessoryNone];
            [[self tableViewCellFullOuterJoin] setAccessoryType:    UITableViewCellAccessoryNone];
            [[self tableViewCellInnerJoin] setAccessoryType:        UITableViewCellAccessoryNone];
            [[self tableViewCellLeftOuterJoin] setAccessoryType:    UITableViewCellAccessoryNone];
            [[self tableViewCellNaturalJoin] setAccessoryType:      UITableViewCellAccessoryNone];
            [[self tableViewCellRightOuterJoin] setAccessoryType:   UITableViewCellAccessoryCheckmark];

            break;
        default:
            
            [[self tableViewCellCrossJoin] setAccessoryType:        UITableViewCellAccessoryNone];
            [[self tableViewCellEquiJoin] setAccessoryType:         UITableViewCellAccessoryNone];
            [[self tableViewCellFullOuterJoin] setAccessoryType:    UITableViewCellAccessoryNone];
            [[self tableViewCellInnerJoin] setAccessoryType:        UITableViewCellAccessoryNone];
            [[self tableViewCellLeftOuterJoin] setAccessoryType:    UITableViewCellAccessoryNone];
            [[self tableViewCellNaturalJoin] setAccessoryType:      UITableViewCellAccessoryNone];
            [[self tableViewCellRightOuterJoin] setAccessoryType:   UITableViewCellAccessoryNone];
            
            break;
    }
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    MNSLinkType linktype = NSNotFound;
    
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
    
    if ((NSInteger)linktype != NSNotFound) {
        [self checkLinkType:linktype];
        [self.delegate viewControllerSchemaAddLinkJoinTypeDidFinishWith: linktype
                                                                   from: self.document];
    }

}

@end
