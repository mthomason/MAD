//
//  MFMailComposeViewController+Designer.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/7/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MFMailComposeViewController_FileManager_h
#define Reports_MFMailComposeViewController_FileManager_h

#import <MessageUI/MessageUI.h>
//#import <MADCocoaExtensions/MADCocoaExtensions.h>

@interface MFMailComposeViewController (FileManager)

    + (instancetype)contactUs:(id<MFMailComposeViewControllerDelegate>) mailComposeDelegate;

@end

#endif
