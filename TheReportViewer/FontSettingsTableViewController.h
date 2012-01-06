//
//  fontSettingsTableViewController.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FontSettingsTableViewController;

@protocol FontSettingsTableViewControllerDelegate
- (void)fontSettingsTableViewControllerDidSelectFontList:(FontSettingsTableViewController *)controller;
@end

@interface FontSettingsTableViewController : UITableViewController
    <UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <FontSettingsTableViewControllerDelegate> delegate;

@property (retain, nonatomic) IBOutlet UITableViewCell *fontLabelTableViewCell;
@property (retain, nonatomic) IBOutlet UILabel *labelFontName;
@property (retain, nonatomic) IBOutlet UISegmentedControl *segControlFontStyle;
@property (retain, nonatomic) IBOutlet UILabel *labelFontSize;
@property (retain, nonatomic) IBOutlet UIStepper *stepperFontSize;

- (IBAction)stepperFontSizeValueChanged:(id)sender;
- (void)updateFontSizeDisplay;

@end