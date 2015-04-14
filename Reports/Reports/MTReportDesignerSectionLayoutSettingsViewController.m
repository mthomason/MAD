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
#import "UIColor+EverydayApps.h"

NSString * const MTReportDesignerSectionLayoutSettingsViewControllerIdentifier = @"MTReportDesignerSectionLayoutSettingsViewControllerIdentifier";

@interface MTReportDesignerSectionLayoutSettingsViewController ()

@property (nonatomic, weak) IBOutlet UILabel *labelHeight;
@property (nonatomic, weak) IBOutlet UILabel *labelNumberOfRows;

@property (nonatomic, weak) IBOutlet UIStepper *heightStepper;
@property (nonatomic, weak) IBOutlet UIStepper *rowsStepper;

@property (nonatomic, weak) IBOutlet UISwitch *switchFormFeed;
@property (nonatomic, weak) IBOutlet UISwitch *switchVisibility;

@end

@implementation MTReportDesignerSectionLayoutSettingsViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.opaque = YES;
    self.navigationController.navigationBar.tintColor = [UIColor tintColorBlue];
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)updateDisplay {
    self.switchFormFeed.on = self.initalFormFeedEnabled;
    self.switchVisibility.on = self.initalVisibility;
    self.heightStepper.value = self.initalHeightValue * 2;
    self.rowsStepper.value = self.initalNumberOfRows;
    
    [self setNumberOfRowsLabel: self.initalNumberOfRows];
    [self setHeighLabel: self.initalHeightValue];
    
}

- (void)setHeighLabel:(double)height {
    NSString *localizedFormatString = NSLocalizedString(@"Height: %0.1f pts", @"Something like - Height: 44 pts");
    NSString *localizedHeight = [NSString stringWithFormat:localizedFormatString, height];
    self.labelHeight.text = localizedHeight;
}

- (void)setNumberOfRowsLabel:(NSUInteger)numberOfRows {
    NSNumber *numberOfRowsWrapper = @(numberOfRows);
    NSString *localizedNumberOfRows = [NSNumberFormatter localizedStringFromNumber: numberOfRowsWrapper
                                                                       numberStyle: NSNumberFormatterSpellOutStyle];
    NSString *localizedFormatString = NSLocalizedString(@"Rows: %@", @"Something like - Rows: two");
    NSString *localizedHeight = [NSString stringWithFormat:localizedFormatString, localizedNumberOfRows];
    self.labelNumberOfRows.text = localizedHeight;
}

- (IBAction)heightChanged:(id)sender {
    double stepperValue = [self stepperValueNormalized];
    [self setHeighLabel: stepperValue];
    [self.delegate sectionLayoutDidUpdateHeight: stepperValue];
}

- (IBAction)numberOfRowsChanged:(UIStepper *)sender {
    [self setNumberOfRowsLabel:sender.value];
    [self.delegate sectionLayoutDidUpdateNumberOfRows:sender.value];
}

- (IBAction)valueChangedVisibility:(id)sender {
    [self.delegate sectionLayoutDidUpdateVisibility:self.switchVisibility.isOn];
}

- (IBAction)valueChangedNewPageAfter:(id)sender {
    [self.delegate layoutSettings: self
                     newPageAfter: self.switchFormFeed.isOn];
}

#pragma mark - Helpers

- (double)stepperValueNormalized {
    return self.heightStepper.value / 2;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { }

- (IBAction)switchNewPageAfter:(id)sender {

}

@end
