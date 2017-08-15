//
//  MADPromptOperationDisplayError.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADPromptOperationDisplayError.h"
#import <os/log.h>
#import <UIKit/UIAlertController.h>
#import "MADMutualExclusive.h"
#import "MADDefer.h"
#import "MADPromptOperationDisplayErrorProtocol.h"

static NSString * const TextYes = @"Dismiss";

@interface MADPromptOperationDisplayError ()

    @property (nonatomic, readwrite, assign) BOOL result;
    @property (nonatomic, copy) NSError *error;
    @property (nonatomic, weak) UIViewController *viewController;
    @property (nonatomic, readwrite, assign) BOOL alertDisplayed;

@end

@implementation MADPromptOperationDisplayError

- (void)dealloc {
    os_log_info(OS_LOG_DEFAULT, "%s", __PRETTY_FUNCTION__);
}

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
        os_log_info(OS_LOG_DEFAULT, "%s", __PRETTY_FUNCTION__);
        _tagDependency = tagDependency;
        _viewController = viewController;
        _error = error.copy;
        _result = NO;
        //MADMutualExclusiveCondition *condition = [MADMutualExclusiveCondition newMutualExclusiveConditionAlertMutex];
        //[self addCondition:condition];
    }
    return self;
}

- (NSError *)errorFromDependencies {
    NSError *error = nil;
    NSArray<__kindof NSOperation *> *dependencies = self.dependencies;
    for (NSOperation *dependency in dependencies) {
        
        if ([dependency conformsToProtocol:@protocol(MADPromptOperationDisplayErrorProtocol)]) {
            
            NSObject <MADPromptOperationDisplayErrorProtocol> *bumbDependency = (NSObject <MADPromptOperationDisplayErrorProtocol> *)dependency;
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
    os_log_info(OS_LOG_DEFAULT, "%s", __PRETTY_FUNCTION__);

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

    MADPromptOperationDisplayError * __weak weakSelf = self;
    NSString *title = NSLocalizedString(TextYes, TextYes);
    
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle: title
                                                       style: UIAlertActionStyleDefault
                                                     handler: ^(UIAlertAction * _Nonnull action) {
        MADPromptOperationDisplayError *strongself = weakSelf;
        strongself.result = YES;
        strongself.alertDisplayed = YES;
        [strongself performSelector:@selector(finish)];
        strongself.viewController = nil;
    }];
    
    [alertController addAction:actionOK];
    
    UIViewController * __weak viewController = self.viewController;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Show error alert:", __PRETTY_FUNCTION__);
        UIViewController *sViewController = viewController;
        sViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [sViewController presentViewController: alertController animated: YES completion: nil];
    }];
}

@end
