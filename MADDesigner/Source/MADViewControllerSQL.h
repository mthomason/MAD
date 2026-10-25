//
//  MUIViewControllerShowSql.h
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTShowSqlViewController_h
#define Reports_MTShowSqlViewController_h

#import <UIKit/UIViewController.h>

@protocol MADViewControllerStandardProtocol;

@class MADocument, MADQuery, UITextView, UISegmentedControl, UIButton, UILabel, UIStackView;

@interface MADViewControllerSQL : UIViewController

@property (nonatomic, weak) id <MADViewControllerStandardProtocol> delegate;
@property (nonatomic, weak) MADocument *document;
@property (nonatomic, weak) IBOutlet UITextView *textView;

// The SQL entry modes (docs/project/MAD_SQL_ENTRY.md §3), built in code over the
// storyboard's read-only text view: a View/Edit switch in the navigation bar;
// View's Generated / As entered tabs; Edit's monospaced editor with Revert,
// Validate and Apply.
@property (nonatomic, strong) UISegmentedControl *modeControl;
@property (nonatomic, strong) UISegmentedControl *tabControl;
@property (nonatomic, strong) UITextView *editTextView;
@property (nonatomic, strong) UIButton *revertButton;
@property (nonatomic, strong) UIButton *validateButton;
@property (nonatomic, strong) UIButton *applyButton;
@property (nonatomic, strong) UIStackView *buttonsRow;
@property (nonatomic, strong) UILabel *statusLabel;

- (IBAction)done:(id)sender;

@end

#endif
