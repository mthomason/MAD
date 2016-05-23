//
//  MFMailComposeViewController+Constructors.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 5/29/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MFMailComposeViewController+Constructors.h"
#import "UIColor+EverydayApps.h"

@implementation MFMailComposeViewController (Constructors)

+ (instancetype)title:(NSString *)title
                 body:(NSString *)body
   userInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom NS_RETURNS_RETAINED {
    
    MFMailComposeViewController	*mailComposer = [[MFMailComposeViewController alloc] init];
    mailComposer.subject = title;
    [mailComposer setMessageBody:body isHTML:NO];
    mailComposer.navigationController.navigationBar.barTintColor = [MADColorEverydayApps newColorAnalogous4];
    
    if (userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;
        mailComposer.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        mailComposer.providesPresentationContextTransitionStyle = YES;
        mailComposer.modalInPopover = NO;
    }
    return mailComposer;
}



+ (instancetype)body:(NSString *)body
          attachment:(NSURL *)attachmentURL
            mimeType:(NSString *)mimeType
  userInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom NS_RETURNS_RETAINED {
    
    NSData *data = [NSData dataWithContentsOfURL:attachmentURL];
    NSString *formatString = NSLocalizedString(@"MAD Document %@.", @"MAD Document %@.");
    NSString *documentTitle = [NSString stringWithFormat:formatString, attachmentURL.lastPathComponent];
    
    MFMailComposeViewController	*mailComposer = [self title:documentTitle body:body userInterfaceIdiom:userInterfaceIdiom];

    NSString *lastPathComponent = attachmentURL.lastPathComponent.copy ?: @"";
    [mailComposer addAttachmentData:data
                           mimeType:mimeType
                           fileName:lastPathComponent];
    return mailComposer;
}

@end
