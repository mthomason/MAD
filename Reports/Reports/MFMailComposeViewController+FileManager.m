//
//  MFMailComposeViewController+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/7/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MFMailComposeViewController+FileManager.h"

@implementation MFMailComposeViewController (FileManager)

+ (instancetype)contactUs:(id<MFMailComposeViewControllerDelegate>) mailComposeDelegate {
    MFMailComposeViewController	*controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = mailComposeDelegate;
    controller.toRecipients = @[@"admin@everydayapps.com"];
    controller.subject = @"MAD Designer";
    controller.navigationController.navigationBar.barTintColor = [UIColor tintColorAnalogous4];
    return controller;
}

@end
