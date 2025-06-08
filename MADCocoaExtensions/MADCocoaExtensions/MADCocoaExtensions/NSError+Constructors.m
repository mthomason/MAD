//
//  NSError+Constructors.m
//  MAD
//
//  Created by Michael Thomason on 4/1/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "NSError+Constructors.h"
#import "UIApplication+Helpers.h"

#import <UIKit/UIAlertController.h>

typedef void (^MTBlockErrorDismiss)(NSInteger buttonIndex);

@implementation NSError (Constructors)

+ (void)presentError:(NSError *)error onViewController:(UIViewController *)viewController
		  completion:(void (^)(BOOL success))completion {
	
	if (error == nil) {
		completion(YES);
		return;
	}
	UIViewController *displayController = viewController ?:  [UIApplication topViewController];
	displayController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
	
	NSString *localizedDescription = [error.localizedDescription copy];
	NSString *localizedFailureReason = [error.localizedFailureReason copy];
	NSError *underlyingError = [error.userInfo[NSUnderlyingErrorKey] copy];
	
	if ([underlyingError localizedDescription] != nil) {
		localizedDescription = underlyingError.localizedDescription;
		localizedFailureReason = underlyingError.localizedFailureReason;
	}
	
	UIAlertController *alert = [UIAlertController alertControllerWithTitle: localizedFailureReason
																   message: localizedDescription
															preferredStyle: UIAlertControllerStyleAlert];

	UIAlertAction *ok = [UIAlertAction actionWithTitle: NSLocalizedString(@"Dismiss", @"Dismiss")
												 style: UIAlertActionStyleDefault
											   handler: ^(UIAlertAction *action) {
		if (completion) completion(YES);
	}];
	[alert addAction:ok];
	
	[displayController presentViewController:alert animated:YES completion:NULL];
	
}

@end
