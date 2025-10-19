//
//  MUIViewControllerReportDesigner.h
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADDesignerViewController_h
#define MAD_MADDesignerViewController_h

#import "MADViewControllerDocumentProtocol.h"
#import "MADViewControllerProtocol.h"
#import "MADTabBarItemProtocol.h"
#import <UIKit/UIViewController.h>

@protocol MADViewControllerStandardProtocol;

@interface MADDesignerViewController : UIViewController <MADViewControllerDocumentProtocol, MADViewControllerProtocol, MADTabBarImageProtocol>

@property (nonatomic, weak) IBOutlet id <MADViewControllerStandardProtocol> delegate;
@property (nonatomic, assign) BOOL hidesStatusBar;

+ (instancetype)newDesignerViewController:(MADocument *)document;
- (IBAction)unwindToDesigner:(UIStoryboardSegue *)action;
- (IBAction)actionHideToolbox;

@end

#endif
