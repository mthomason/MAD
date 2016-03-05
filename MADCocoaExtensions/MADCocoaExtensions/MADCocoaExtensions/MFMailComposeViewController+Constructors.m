//
//  MFMailComposeViewController+Constructors.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 5/29/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MFMailComposeViewController+Constructors.h"
#import "MADColor.h"

@implementation MADMailComposeViewController

+ (instancetype)title:(NSString *)title
                 body:(NSString *)body
   userInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom NS_RETURNS_RETAINED {
    
    MADMailComposeViewController	*mailComposer = [[self alloc] init];
    mailComposer.subject = title;
    [mailComposer setMessageBody:body isHTML:NO];
    mailComposer.navigationController.navigationBar.barTintColor = [MADColor tintColorAnalogous4];
    
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
    
    MADMailComposeViewController	*mailComposer = [self title:documentTitle body:body userInterfaceIdiom:userInterfaceIdiom];

    [mailComposer addAttachmentData:data mimeType:mimeType fileName:attachmentURL.lastPathComponent];
    return mailComposer;
}

@end
