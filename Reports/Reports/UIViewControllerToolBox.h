//
//  UIViewControllerToolBox.h
//  Reports
//
//  Created by Michael Thomason on 1/28/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerFontSettings.h"
#import "UITableViewControllerFontSelector.h"

@protocol UIViewControllerToolBoxDelegate
- (void)heightChanged:(CGFloat)newHeight;
- (void)hideToolbox;
@end

@interface UIViewControllerToolBox : UIViewController
    <UINavigationBarDelegate, FontSettingsTableViewControllerDelegate,
        UITableViewControllerFontSelectorDelegate>

@property (assign, nonatomic) IBOutlet id <UIViewControllerToolBoxDelegate> delegate;
- (void)showToolboxWithObjectIds:(NSSet *)objectIds;
- (void)setFontDelegates:(id)delegate;
- (IBAction)valueChanged:(id)sender;
- (CGFloat)contentHeight;

@end