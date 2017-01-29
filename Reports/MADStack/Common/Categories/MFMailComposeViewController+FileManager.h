//
//  MFMailComposeViewController+Designer.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/7/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MFMailComposeViewController_FileManager_h
#define Reports_MFMailComposeViewController_FileManager_h

#import <MessageUI/MessageUI.h>

@interface MFMailComposeViewController (FileManager)

    + (instancetype)contactUs:(id<MFMailComposeViewControllerDelegate>) mailComposeDelegate;

@end

#endif
