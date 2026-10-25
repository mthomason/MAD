//
//  MADOperationPromptError.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADOperationPromptError.h"
#import "MADMutualExclusive.h"
#import <MADFoundation/madlog.h>

#import <MADFoundation/MADOperationPromptErrorProtocol.h>

#import <UIKit/UIAlertController.h>

static NSString * const TextYes = @"Dismiss";

@interface MADOperationPromptError ()

	@property (nonatomic, readwrite, assign) BOOL result;
	@property (nonatomic, readwrite, assign) BOOL alertDisplayed;
	@property (nonatomic, copy) NSError *error;
	@property (nonatomic, weak) UIViewController *viewController;

@end

@implementation MADOperationPromptError

- (void)dealloc { }

- (instancetype)initWithViewController:(UIViewController * __weak)viewController {
	return [self initWithError:nil tagDependency:0 viewController:viewController];
}

- (instancetype)initWithError:(NSError *)error
			   viewController:(UIViewController * __weak)viewController {
	return [self initWithError:error tagDependency:0 viewController:viewController];
}

- (instancetype)initWithDependencyTag:(NSUInteger)dependencyTag
					   viewController:(UIViewController * __weak)viewController {
	return [self initWithError:nil tagDependency:dependencyTag viewController:viewController];
}

- (instancetype)initWithError:(NSError *)error tagDependency:(NSUInteger)tagDependency
			   viewController:(UIViewController * __weak)viewController {
	if (self = [super init]) {
		_tagDependency = tagDependency;
		_viewController = viewController;
		_error = error.copy;
		_result = NO;
		//MADMutualExclusiveCondition *condition = [MADMutualExclusiveCondition newMutualExclusiveConditionAlertMutex];
		//[self addCondition:condition];
	}
	return self;
}

- (BOOL)isAsynchronous {
	return YES;
}

- (BOOL)alertDisplayedAffirmed { return self.alertDisplayed && self.result; }

- (NSError *)errorFromDependencies {
	NSError *error = nil;
	NSArray<__kindof NSOperation *> *dependencies = self.dependencies;
	for (NSOperation *dependency in dependencies) {
		
		if ([dependency conformsToProtocol:@protocol(MADOperationPromptErrorProtocol)]) {
			
			NSObject <MADOperationPromptErrorProtocol> *bumbDependency;
			bumbDependency = (NSObject <MADOperationPromptErrorProtocol> *)dependency;
			if ([bumbDependency displayError]) {
				
				if (self.tagDependency == 0 || self.tagDependency == [bumbDependency tag]) {
					error = [bumbDependency error];
					break;
				}
				
			}
			
		}
	}
	return error;
}

- (void)execute {	
	if (self.cancelled) {
		return [self finish];
	}
	
	NSError *error = self.error;
	if (error == nil) { // Find the error in dependencies if it wasn't passed in.
		error = [self errorFromDependencies];
	}

	// Eh, error, no error, or it's a good thing, right?
	if (error == nil) {
		[self finish];
		return;
	}

	NSString *localizedDescription;
	NSString *localizedFailureReason;
	
	NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
	
	if (underlyingError.localizedDescription != nil) {
		localizedDescription = underlyingError.localizedDescription;
		localizedFailureReason = underlyingError.localizedFailureReason;
	} else {
		localizedDescription = error.localizedDescription;
		localizedFailureReason = error.localizedFailureReason;
	}
	
	UIAlertController *alertController;
	alertController = [UIAlertController alertControllerWithTitle: localizedFailureReason
														  message: localizedDescription
												   preferredStyle: UIAlertControllerStyleAlert];

	MADOperationPromptError * __weak weakSelf = self;
	NSString *title = NSLocalizedString(TextYes, TextYes);
	
	UIAlertAction *actionOK = [UIAlertAction actionWithTitle: title
													   style: UIAlertActionStyleDefault
													 handler: ^(UIAlertAction * _Nonnull __unused action) {
		MADOperationPromptError *strongself = weakSelf;
		strongself.result = YES;
		strongself.alertDisplayed = YES;
		[strongself performSelector:@selector(finish)];
		strongself.viewController = nil;
	}];
	
	[alertController addAction:actionOK];
	
	UIViewController * __weak viewController = self.viewController;
	[[NSOperationQueue mainQueue] addOperationWithBlock:^ {
		UIViewController *sViewController = viewController;
		sViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
		[sViewController presentViewController: alertController animated: YES completion: nil];
	}];
}

@end
