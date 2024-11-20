//
//  MFMailComposeViewController+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/7/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MFMailComposeViewController+FileManager.h"

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

@implementation MFMailComposeViewController (FileManager)

+ (instancetype)contactUs:(id<MFMailComposeViewControllerDelegate>) mailComposeDelegate {
    MFMailComposeViewController	*controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = mailComposeDelegate;
    controller.toRecipients = @[@"admin@everydayapps.com"];
    controller.subject = @"MAD Designer";
    controller.navigationController.navigationBar.barTintColor = [MADColorEverydayApps newColorAnalogous4];
    return controller;
}

@end
