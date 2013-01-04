//
//  fontSettingsTableViewController.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/5/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTFont.h"

@class UITableViewControllerFontSettings;

@protocol FontSettingsTableViewControllerDelegate
- (void)fontSettingsTableViewControllerDidSelectFontList:(UITableViewControllerFontSettings *)controller;
@end

@interface UITableViewControllerFontSettings : UITableViewController
    <UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <FontSettingsTableViewControllerDelegate> delegate;

@property (retain, nonatomic) IBOutlet UITableViewCell *fontLabelTableViewCell;
@property (retain, nonatomic) IBOutlet UILabel *labelFontName;
@property (retain, nonatomic) IBOutlet UISegmentedControl *segControlFontStyle;
@property (retain, nonatomic) IBOutlet UILabel *labelFontSize;
@property (retain, nonatomic) IBOutlet UIStepper *stepperFontSize;
@property (retain, nonatomic) IBOutlet UIButton *buttonBold;
@property (retain, nonatomic) IBOutlet UIButton *buttonItalic;
@property (retain, nonatomic) IBOutlet UIButton *buttonStrike;
@property (retain, nonatomic) IBOutlet UIButton *buttonUnderline;

- (void)updateFontSizeDisplay;
- (void)chooseFont:(MTFont *)font;
- (void)initalizeDocumentObjects:(NSSet *)objectIds;    //Call this before you add view to super.
- (void)setSelectedDocumentObjects:(NSSet *)objectIds;  //This is called on viewWillAppear... only call on change.

- (IBAction)controlValueChanged:(id)sender;

@end