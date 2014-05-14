//
//  UITableViewControllerFontSelector.m
//  Reports
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTReportDesignerFontSelectorViewController.h"
#import "UIDevice+Hack.h"
#import "MTFont.h"
#import "MTLog.h"

@interface MTReportDesignerFontSelectorViewController()

@property (nonatomic, strong) MTFont *initalSelectedFont;

@end

@implementation MTReportDesignerFontSelectorViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self tableView] setDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self checkSelectedFont:[self initalSelectedFont]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if ([UIDevice isPad] == NO) {
        //CGFloat insetOffset = [[[self tabBarController] tabBar] frame].size.height;
        UIEdgeInsets tableInset = UIEdgeInsetsMake(0.0000f, 0.0000f, 50.0000f, 0.0000f);
        [[self tableView] setContentInset:tableInset];
        [[self tableView] setScrollIndicatorInsets:tableInset];
    }
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:indexPath];

    if ([cell isEqual:[self tableViewCellFontAmericanTypewriter]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyAmericanTypewriter];
    } else if ([cell isEqual:[self tableViewCellFontArial]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyArial];
    } else if ([cell isEqual:[self tableViewCellFontCourierNew]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyCourierNew];
    } else if ([cell isEqual:[self tableViewCellFontCourier]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyCourier];
    } else if ([cell isEqual:[self tableViewCellFontGeorgia]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyGeorgia];
    } else if ([cell isEqual:[self tableViewCellFontHelvetica]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyHelvetica];
    } else if ([cell isEqual:[self tableViewCellFontHelveticaNeue]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyHelveticaNeue];
    } else if ([cell isEqual:[self tableViewCellFontTimesNewRoman]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyTimesNewRoman];
    } else if ([cell isEqual:[self tableViewCellFontTrebuchet]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyTrebuchet];
    } else if ([cell isEqual:[self tableViewCellFontVerdana]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyVerdana];
    } else if ([cell isEqual:[self tableViewCellFontZapfino]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyZapfino];
    }
    
    if ([cell accessoryType] != UITableViewCellAccessoryCheckmark) {
        [self uncheckAllCells];
        
        //Check this box, or not (could test)
        [[[self tableView] cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    
    [[self tableView] deselectRowAtIndexPath:indexPath animated:YES];
    
}

- (void)checkSelectedFont:(MTFont *)font {
    [self uncheckAllCells];
    
    if ([[font name] isEqualToString:MTFontFamilyAmericanTypewriter]) {
        [[self tableViewCellFontAmericanTypewriter] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else if ([[font name] isEqualToString:MTFontFamilyArial]) {
        [[self tableViewCellFontArial] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else if ([[font name] isEqualToString:MTFontFamilyCourierNew]) {
        [[self tableViewCellFontCourierNew] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else if ([[font name] isEqualToString:MTFontFamilyCourier]) {
        [[self tableViewCellFontCourier] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else if ([[font name] isEqualToString:MTFontFamilyGeorgia]) {
        [[self tableViewCellFontGeorgia] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else if ([[font name] isEqualToString:MTFontFamilyHelvetica]) {
        [[self tableViewCellFontHelvetica] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else if ([[font name] isEqualToString:MTFontFamilyHelveticaNeue]) {
        [[self tableViewCellFontHelveticaNeue] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else if ([[font name] isEqualToString:MTFontFamilyTimesNewRoman]) {
        [[self tableViewCellFontTimesNewRoman] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else if ([[font name] isEqualToString:MTFontFamilyTrebuchet]) {
        [[self tableViewCellFontTrebuchet] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else if ([[font name] isEqualToString:MTFontFamilyVerdana]) {
        [[self tableViewCellFontVerdana] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else if ([[font name] isEqualToString:MTFontFamilyZapfino]) {
        [[self tableViewCellFontZapfino] setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
}

- (void)setSelectedFont:(MTFont *)font {
    [self setInitalSelectedFont:font];
}

- (void)uncheckAllCells {
    [[self tableViewCellFontAmericanTypewriter] setAccessoryType:UITableViewCellAccessoryNone];
    [[self tableViewCellFontArial] setAccessoryType:UITableViewCellAccessoryNone];
    [[self tableViewCellFontCourierNew] setAccessoryType:UITableViewCellAccessoryNone];
    [[self tableViewCellFontCourier] setAccessoryType:UITableViewCellAccessoryNone];
    [[self tableViewCellFontGeorgia] setAccessoryType:UITableViewCellAccessoryNone];
    [[self tableViewCellFontHelvetica] setAccessoryType:UITableViewCellAccessoryNone];
    [[self tableViewCellFontHelveticaNeue] setAccessoryType:UITableViewCellAccessoryNone];
    [[self tableViewCellFontTimesNewRoman] setAccessoryType:UITableViewCellAccessoryNone];
    [[self tableViewCellFontTrebuchet] setAccessoryType:UITableViewCellAccessoryNone];
    [[self tableViewCellFontVerdana] setAccessoryType:UITableViewCellAccessoryNone];
    [[self tableViewCellFontZapfino] setAccessoryType:UITableViewCellAccessoryNone];
    
}

@end
