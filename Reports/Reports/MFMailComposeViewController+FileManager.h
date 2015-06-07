//
//  MFMailComposeViewController+Designer.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/7/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <MessageUI/MessageUI.h>

@interface MFMailComposeViewController (FileManager)

+ (instancetype)contactUs:(id<MFMailComposeViewControllerDelegate>) mailComposeDelegate;

@end
