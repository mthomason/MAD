//
//  NSError+Constructors.m
//  MAD
//
//  Created by Michael Thomason on 4/1/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "NSError+Constructors.h"
#if TARGET_OS_IPHONE
#import <MADFoundation/madlog.h>
#import "UIApplication+Helpers.h"

#import <UIKit/UIAlertController.h>

typedef void (^MTBlockErrorDismiss)(NSInteger buttonIndex);

@implementation NSError (Constructors)

+ (void)presentError:(NSError *)error onViewController:(UIViewController *)viewController
		  completion:(void (^)(BOOL success))completion {
	
	if (error == nil) {
		os_log_error(GetMadExtLog(), "Error was nil.  This is unexpected.");
		if (completion != nil) completion(YES);
		return;
	} else {
		os_log_error(GetMadExtLog(), "Error: %@", error);
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
											   handler: ^(UIAlertAction *__unused action) {
		if (completion != nil) completion(YES);
	}];
	[alert addAction:ok];
	
	[displayController presentViewController:alert animated:YES completion:nil];
	
}

@end
#endif
