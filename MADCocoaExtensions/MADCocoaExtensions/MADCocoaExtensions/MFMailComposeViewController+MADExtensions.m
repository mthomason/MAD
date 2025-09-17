//
//  MFMailComposeViewController+Constructors.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 5/29/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MFMailComposeViewController+MADExtensions.h"
#import "UIColor+EverydayApps.h"

@implementation MFMailComposeViewController (MADExtensions)

+ (instancetype)ma_newMailComposeViewControllerWithTitle:(NSString *)title
													body:(NSString *)body
									  userInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom {
	
	MFMailComposeViewController *mailComposer = [[self alloc] init];
	mailComposer.subject = title;
	[mailComposer setMessageBody:body isHTML:NO];
	mailComposer.navigationController.navigationBar.barTintColor = [MADColorEverydayApps newColorAnalogous4];
	
	if (userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;
		mailComposer.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		mailComposer.providesPresentationContextTransitionStyle = YES;
		mailComposer.modalInPresentation = NO;
	}
	return mailComposer;
}

+ (instancetype)ma_newMailComposeViewControllerWithBody:(NSString *)body
											 attachment:(NSURL *)attachmentURL
											   mimeType:(NSString *)mimeType
									 userInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom {
	
	NSString *documentTitle = [[NSString alloc] initWithFormat:NSLocalizedString(@"MAD Document %@.", @"MAD Document %@."), attachmentURL.lastPathComponent];
	
	MFMailComposeViewController *mailComposer = [self ma_newMailComposeViewControllerWithTitle:documentTitle
																						  body:body
																			userInterfaceIdiom:userInterfaceIdiom];

	NSString *lastPathComponent = [attachmentURL.lastPathComponent copy] ?: @"";
	NSData *data = [NSData dataWithContentsOfURL:attachmentURL];
	[mailComposer addAttachmentData:data
						   mimeType:mimeType
						   fileName:lastPathComponent];
	
	return mailComposer;
}

@end
