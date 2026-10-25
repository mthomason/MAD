//
//  MADMailComposeViewController.h
//  CocoaExtensions
//
//  Created by Michael Thomason on 5/29/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADExtensions_MADMailComposeViewController_h
#define MADExtensions_MADMailComposeViewController_h

#import <MessageUI/MFMailComposeViewController.h>

@interface MFMailComposeViewController (MADExtensions)

+ (instancetype)ma_newMailComposeViewControllerWithTitle:(NSString *)title
													body:(NSString *)body
									  userInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom;

+ (instancetype)ma_newMailComposeViewControllerWithBody:(NSString *)body
											 attachment:(NSURL *)attachmentURL
											   mimeType:(NSString *)mimeType
									 userInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom;

@end

#endif
