//
//  imageInformationViewController.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ImageInformationViewController;

@protocol ImageInformationViewControllerDelegate
- (void)imageInformationViewControllerDidFinish:(ImageInformationViewController *)controller;
@end

@interface ImageInformationViewController : UIViewController

@property (assign, nonatomic) IBOutlet id <ImageInformationViewControllerDelegate> delegate;

- (IBAction)done:(id)sender;

@end