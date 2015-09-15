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

#import "MADFontSelectorViewController.h"
#import "MTFont.h"
#import "UIViewController+UI.h"

@interface MADFontSelectorViewController()

@property (nonatomic, strong) MTFont *initalSelectedFont;

@end

@implementation MADFontSelectorViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [UIColor tintColorRed];
    self.navigationController.navigationBar.alpha = 1.0000f;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden: NO animated: animated];
    if (self.clearsBackground) {
        self.tableView.backgroundView = nil;
    }

    [self checkSelectedFont:self.initalSelectedFont];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    self.navigationController.parentViewController.preferredContentSize = CGSizeMake(320.0000f, 680.0000f);

    self.navigationController.navigationBar.frame = CGRectMake(self.navigationController.navigationBar.frame.origin.x, self.topLayoutGuide.length - self.navigationController.navigationBar.frame.size.height, self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.frame.size.height);
    self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width, self.bottomLayoutGuide.length, CGSizeZero.width);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width, self.bottomLayoutGuide.length, CGSizeZero.width);
    if (self.firstTimeViewWillLayoutSubviews) {
        self.tableView.contentOffset = CGPointMake(CGPointZero.x, CGPointZero.y - self.topLayoutGuide.length);
    }

}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];

    if ([cell isEqual:[self tableViewCellFontAmericanTypewriter]]) {
        [self.delegate uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyAmericanTypewriter];
    } else if ([cell isEqual:[self tableViewCellFontArial]]) {
        [self.delegate uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyArial];
    } else if ([cell isEqual:[self tableViewCellFontCourierNew]]) {
        [self.delegate uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyCourierNew];
    } else if ([cell isEqual:[self tableViewCellFontCourier]]) {
        [self.delegate uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyCourier];
    } else if ([cell isEqual:[self tableViewCellFontGeorgia]]) {
        [self.delegate uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyGeorgia];
    } else if ([cell isEqual:[self tableViewCellFontHelvetica]]) {
        [self.delegate uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyHelvetica];
    } else if ([cell isEqual:[self tableViewCellFontHelveticaNeue]]) {
        [self.delegate uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyHelveticaNeue];
    } else if ([cell isEqual:[self tableViewCellFontTimesNewRoman]]) {
        [self.delegate uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyTimesNewRoman];
    } else if ([cell isEqual:[self tableViewCellFontTrebuchet]]) {
        [self.delegate uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyTrebuchet];
    } else if ([cell isEqual:[self tableViewCellFontVerdana]]) {
        [self.delegate uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyVerdana];
    } else if ([cell isEqual:[self tableViewCellFontZapfino]]) {
        [self.delegate uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyZapfino];
    }              
    
    if (cell.accessoryType != UITableViewCellAccessoryCheckmark) {
        [self uncheckAllCells];
        
        //Check this box, or not (could test)
        [[self.tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

- (void)checkSelectedFont:(MTFont *)font {
    [self uncheckAllCells];
    
    if ([font.familyName isEqualToString:MTFontFamilyAmericanTypewriter]) {
        [[self tableViewCellFontAmericanTypewriter] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else if ([font.familyName isEqualToString:MTFontFamilyArial]) {
        [[self tableViewCellFontArial] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else if ([font.familyName isEqualToString:MTFontFamilyCourierNew]) {
        [[self tableViewCellFontCourierNew] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else if ([font.familyName isEqualToString:MTFontFamilyCourier]) {
        [[self tableViewCellFontCourier] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else if ([font.familyName isEqualToString:MTFontFamilyGeorgia]) {
        [[self tableViewCellFontGeorgia] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else if ([font.familyName isEqualToString:MTFontFamilyHelvetica]) {
        [[self tableViewCellFontHelvetica] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else if ([font.familyName isEqualToString:MTFontFamilyHelveticaNeue]) {
        [[self tableViewCellFontHelveticaNeue] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else if ([font.familyName isEqualToString:MTFontFamilyTimesNewRoman]) {
        [[self tableViewCellFontTimesNewRoman] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else if ([font.familyName isEqualToString:MTFontFamilyTrebuchet]) {
        [[self tableViewCellFontTrebuchet] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else if ([font.familyName isEqualToString:MTFontFamilyVerdana]) {
        [[self tableViewCellFontVerdana] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else if ([font.familyName isEqualToString:MTFontFamilyZapfino]) {
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
