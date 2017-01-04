//
//  MADMailComposeViewController.h
//  CocoaExtensions
//
//  Created by Michael Thomason on 5/29/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADExtensions_MADMailComposeViewController_h
#define MADExtensions_MADMailComposeViewController_h

#import <MessageUI/MFMailComposeViewController.h>

@interface MADMailComposeViewController : MFMailComposeViewController

    + (instancetype)newMailComposeViewControllerWithTitle: (NSString *)title
                                                     body: (NSString *)body
                                       userInterfaceIdiom: (UIUserInterfaceIdiom)userInterfaceIdiom;

    + (instancetype)newMailComposeViewControllerWithBody: (NSString *)body
                                              attachment: (NSURL *)attachmentURL
                                                mimeType: (NSString *)mimeType
                                      userInterfaceIdiom: (UIUserInterfaceIdiom)userInterfaceIdiom;

@end

#endif
