//
//  UITableViewControllerSectionLayoutSettings.m
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTReportDesignerSectionLayoutSettingsViewController.h"

#import <UIKit/UIAccessibility.h>
#import <UIKit/UISwitch.h>
#import <UIKit/UIStepper.h>
#import <UIKit/UILabel.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/UIView+Animations.h>
#import "UIViewController+Designer.h"

static NSString * const MADTextVisible         = @"Visible";
static NSString * const MADTextVisibleHint     = @"Toggles visibility.";
static NSString * const MADTextFormFeed        = @"Form Feed";
static NSString * const MADTextFormFeedHint    = @"Toggles form feed.";

@interface MTReportDesignerSectionLayoutSettingsViewController ()

    @property (nonatomic, weak) IBOutlet UILabel *labelVisible;
    @property (nonatomic, weak) IBOutlet UILabel *labelFormFeed;
    @property (nonatomic, weak) IBOutlet UISwitch *switchFormFeed;
    @property (nonatomic, weak) IBOutlet UISwitch *switchVisibility;
    @property (nonatomic, weak) IBOutlet UITableViewCell *cellVisibility;
    @property (nonatomic, weak) IBOutlet UITableViewCell *cellFormFeed;

@end

@implementation MTReportDesignerSectionLayoutSettingsViewController

+ (instancetype)toolboxSettings {
    return (MTReportDesignerSectionLayoutSettingsViewController *)[UIViewController layoutSettingsViewController];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.autoresizingMask = MADViewAutoresizingFlexable();
    self.labelVisible.text = NSLocalizedString(MADTextVisible, MADTextVisible);
    self.labelFormFeed.text = NSLocalizedString(MADTextFormFeed, MADTextFormFeed);
    self.labelVisible.isAccessibilityElement = NO;
    self.labelFormFeed.isAccessibilityElement = NO;
    self.switchVisibility.isAccessibilityElement = NO;
    self.switchFormFeed.isAccessibilityElement = NO;
    self.cellVisibility.isAccessibilityElement = YES;
    self.cellFormFeed.isAccessibilityElement = YES;
    self.cellVisibility.accessibilityLabel = self.labelVisible.text;
    self.cellVisibility.accessibilityHint = NSLocalizedString(MADTextVisibleHint, MADTextVisibleHint);
    self.cellVisibility.accessibilityTraits = self.cellVisibility.accessibilityTraits | UIAccessibilityTraitButton;
    self.cellFormFeed.accessibilityLabel = self.labelFormFeed.text;
    self.cellFormFeed.accessibilityHint = NSLocalizedString(MADTextFormFeedHint, MADTextFormFeedHint);
    self.cellFormFeed.accessibilityTraits = self.cellFormFeed.accessibilityTraits | UIAccessibilityTraitButton;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.opaque = YES;
    self.navigationController.navigationBar.tintColor = [MADColorEverydayApps newColorBlue];
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(self.tableView.scrollIndicatorInsets.top,
                                                            self.tableView.scrollIndicatorInsets.left,
                                                            CGSizeZero.height,
                                                            self.tableView.scrollIndicatorInsets.right);
    [self updateDisplay];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateDisplay];
}

- (void)updateDisplay {
    self.switchFormFeed.on = self.initalFormFeedEnabled;
    self.switchVisibility.on = self.initalVisibility;
}

- (IBAction)heightChanged:(id)sender { }

- (IBAction)numberOfRowsChanged:(UIStepper *)sender {
    [self.delegate sectionLayoutDidUpdateNumberOfRows:(NSUInteger)sender.value];
}

- (IBAction)valueChangedVisibility:(id)sender {
    [self.delegate sectionLayoutDidUpdateVisibility:self.switchVisibility.isOn];
}

- (IBAction)valueChangedNewPageAfter:(id)sender {
    [self.delegate layoutSettings: self newPageAfter: self.switchFormFeed.isOn];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
            [self.switchVisibility setOn:!self.switchVisibility.on animated:YES];
            break;
        case 1:
            [self.switchFormFeed setOn:!self.switchFormFeed.on animated:YES];
            break;
        default:
            break;
    }
}

- (IBAction)switchNewPageAfter:(id)sender { }

#pragma mark - Accessibility

- (BOOL)accessibilityPerformEscape {
    if ([self.delegate respondsToSelector:@selector(sectionLayoutSettingsDidFinish:)]) {
        [self.delegate sectionLayoutSettingsDidFinish:self];
        return YES;
    } else {
        return NO;
    }
}

@end
