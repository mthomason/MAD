//
//  MADPromptOperationDisplayError.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADPromptOperationDisplayError.h"
#import <UIKit/UIAlertController.h>
#import "MADMutualExclusive.h"
#import "MADDefer.h"

static NSString * const TextYes = @"Dismiss";

@interface MADPromptOperationDisplayError ()

    @property (nonatomic, readwrite, assign) bool result;
    @property (nonatomic, copy) NSError *error;
    @property (nonatomic, weak) UIViewController *viewController;
    @property (nonatomic, readwrite, assign) bool alertDisplayed;

@end

@implementation MADPromptOperationDisplayError

- (void)dealloc {
    NSLog(@"Operation deallocated. %s", __PRETTY_FUNCTION__);
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
        _tagDependency = tagDependency;
        _viewController = viewController;
        _error = error.copy;
        _result = false;
        MADMutualExclusiveCondition *condition = [MADMutualExclusiveCondition newMutualExclusiveConditionAlertMutex];
        [self addCondition:condition];
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

    NSError *error = self.error;
    if (error == nil) { // Find the error in dependencies if it wasn't passed in.
        error = [self errorFromDependencies];
    }

    // Eh, error, no error, or it's a good thing, right?
    if (error == nil) {
        [self finish];
        return;
    }

    NSString *localizedDescription = error.localizedDescription;
    NSString *localizedFailureReason = error.localizedFailureReason;
    
    NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
    
    if (underlyingError.localizedDescription != nil) {
        localizedDescription = underlyingError.localizedDescription;
        localizedFailureReason = underlyingError.localizedFailureReason;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle: localizedFailureReason message: localizedDescription
                                                                      preferredStyle: UIAlertControllerStyleAlert];

    MADPromptOperationDisplayError * __weak weakSelf = self;
    NSString *title = NSLocalizedString(TextYes, TextYes);
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle: title style: UIAlertActionStyleDefault handler: ^(UIAlertAction * _Nonnull action) {
        MADPromptOperationDisplayError * __strong sself = weakSelf;
        sself.result = true;
        sself.alertDisplayed = true;
        defer(^{
            [sself performSelectorInBackground:@selector(finish) withObject:nil];
        });
    }];
    
    [alertController addAction:actionOK];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        UIViewController *viewController = self.viewController;
        viewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [viewController presentViewController: alertController animated: YES completion: nil];
    }];
}

@end
