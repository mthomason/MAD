//
//  MFMailComposeViewController+Constructors.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 5/29/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADMailComposeViewController.h"
#import "UIColor+EverydayApps.h"

@implementation MADMailComposeViewController

+ (instancetype)newMailComposeViewControllerWithTitle: (NSString *)title
                                                 body: (NSString *)body
                                   userInterfaceIdiom: (UIUserInterfaceIdiom)userInterfaceIdiom {
    
    MADMailComposeViewController *mailComposer = [[self alloc] init];
    mailComposer.subject = title;
    [mailComposer setMessageBody:body isHTML:NO];
    mailComposer.navigationController.navigationBar.barTintColor
                                                    = [MADColorEverydayApps newColorAnalogous4];
    
    if (userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;
        mailComposer.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        mailComposer.providesPresentationContextTransitionStyle = YES;
        mailComposer.modalInPopover = NO;
    }
    return mailComposer;
}



+ (instancetype)newMailComposeViewControllerWithBody: (NSString *)body
                                          attachment: (NSURL *)attachmentURL
                                            mimeType: (NSString *)mimeType
                                  userInterfaceIdiom: (UIUserInterfaceIdiom)userInterfaceIdiom {
    
    NSData *data = [NSData dataWithContentsOfURL:attachmentURL];
    NSString *formatString = NSLocalizedString(@"MAD Document %@.", @"MAD Document %@.");
    NSString *documentTitle = [NSString stringWithFormat:formatString,
                                                         attachmentURL.lastPathComponent];
    
    MADMailComposeViewController *mailComposer;
    mailComposer = [self newMailComposeViewControllerWithTitle: documentTitle
                                                          body: body
                                            userInterfaceIdiom: userInterfaceIdiom];

    NSString *lastPathComponent = attachmentURL.lastPathComponent.copy ?: @"";
    [mailComposer addAttachmentData: data
                           mimeType: mimeType
                           fileName: lastPathComponent];
    return mailComposer;
}

@end
