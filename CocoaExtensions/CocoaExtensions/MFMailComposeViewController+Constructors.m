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

+ (instancetype)mailDocument:(NSURL *)fileURL
                    mimeType:(NSString *)mimeType
                       title:(NSString *)title
                        body:(NSString *)body
          userInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom {
    
    NSData *data = [NSData dataWithContentsOfURL:fileURL];
    MFMailComposeViewController	*mailComposer = [[MFMailComposeViewController alloc] init];
    //mailComposer.mailComposeDelegate = self;

    NSString *formatString = NSLocalizedString(@"MAD Document %@.", @"MAD Document %@.");
    mailComposer.subject = [NSString stringWithFormat:formatString, fileURL.lastPathComponent];
    [mailComposer setMessageBody:body isHTML:NO];
    //NSString *name = [NSString stringWithFormat:@"%@.%@", documentReport.fileNa, MADFileExtentionMobleApplicationDocument];
    [mailComposer addAttachmentData:data mimeType:mimeType fileName:fileURL.lastPathComponent];
    mailComposer.navigationController.navigationBar.barTintColor = [UIColor tintColorAnalogous4];
    
    if (userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;
        mailComposer.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        mailComposer.providesPresentationContextTransitionStyle = YES;
        mailComposer.modalInPopover = NO;
    }
    return mailComposer;
}

@end
