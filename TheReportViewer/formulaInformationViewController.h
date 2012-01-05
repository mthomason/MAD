//
//  formulaInformationViewController.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FormulaInformationViewController;

@protocol FormulaInformationViewControllerDelegate
- (void)formulaInformationViewControllerDidFinish:(FormulaInformationViewController *)controller;
@end

@interface FormulaInformationViewController : UIViewController

@property (assign, nonatomic) IBOutlet id <FormulaInformationViewControllerDelegate> delegate;

- (IBAction)done:(id)sender;

@end