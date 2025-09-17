//
//  MADKeyChainSaveCredentials.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/11/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADKeyChainSaveCredentials.h"
#import "MADKeyChainGetCredentials.h"
#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADKeyChain.h>
#import <MAD/MADCredentialSourceType.h>
#import <UIKit/UIViewController.h>
#import <UIKit/UIAlertController.h>

@interface MADKeyChainSaveCredentials()

@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, strong, readwrite) MADCredential *credential;

@end

@implementation MADKeyChainSaveCredentials

- (instancetype)initWithKey:(NSString *)key viewController:(UIViewController *)viewController {
	if (self = [super init]) {
		self.viewController = viewController;
		self.key = [key copy];
	}
	return self;
}

- (BOOL)isAsynchronous { return YES; }


- (void)execute {
	if (self.cancelled) return [self finish];

	MADCredentialSource source = MADCredentialSourceNone;
	NSArray *dependencies = self.dependencies;
	for (MADKeyChainGetCredentials *dependency in dependencies) {
		if ([dependency isKindOfClass:[MADKeyChainGetCredentials class]]) {
			self.credential = [((MADKeyChainGetCredentials *)dependency).credential copy];
			source = ((MADKeyChainGetCredentials *)dependency).source;
			break;
		}
	}
	
	if (self.cancelled) return [self finish];
	
	switch (source) {
		case MADCredentialSourceCredentialPrompt: {
			[self promptToSave:^(UIAlertAction *action) {
				OSStatus status = [MADKeyChain saveUsername: self.credential.username andPassword: self.credential.password forKey: self.key];
				if (status == errSecSuccess) {
					[self finish];
				} else {
					NSError *error = [NSError errorWithDomain:@"MADOSStatus" code:status userInfo:nil];
					[self finishWithError:error];
				};
			}];
			break;
		}
		case MADCredentialSourcePasswordPrompt: {
			
			
			[self promptToSave:^(UIAlertAction *action) {
				OSStatus status = [MADKeyChain savePassword: self.credential.password forKey: self.key];
				if (status == errSecSuccess) {
					[self finish];
				} else {
					NSError *error = [NSError errorWithDomain:@"MADOSStatus" code:status userInfo:nil];
					[self finishWithError:error];
				}

			}];
			
			break;
		}
		case MADCredentialSourceKeychain:
			[self finish];
			
		default:
			[self finish];
			break;
	}
	
}

- (void)promptToSave:(void (^ __nullable)(UIAlertAction *action))actionContinue {
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Save Credentials", @"Save Credentials")
																			 message: NSLocalizedString(@"Would you like to save the credentials to your key chain?", @"Would you like to save the credentials to your key chain?")
																	  preferredStyle: UIAlertControllerStyleAlert];
	
	UIAlertAction *alertActionContinue = [UIAlertAction actionWithTitle: NSLocalizedString(@"Continue", @"Continue")
																  style: UIAlertActionStyleDefault
																handler: actionContinue];

	UIAlertAction *actionCancel = [UIAlertAction actionWithTitle: NSLocalizedString(@"Cancel", @"Cancel")
														   style: UIAlertActionStyleCancel
														 handler: ^(UIAlertAction *action) { }];

	[alertController addAction:alertActionContinue];
	[alertController addAction:actionCancel];
	
	[[NSOperationQueue mainQueue] addOperationWithBlock:^ {
		UIViewController *topViewController = self.viewController;
		if (topViewController != nil) {
			topViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
			[topViewController  presentViewController: alertController animated: YES completion: nil];
		}
	}];
}

@end
