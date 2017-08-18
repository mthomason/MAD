//
//  MADOperationPromptPolarQuestion.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationPromptPolarQuestion.h"
#import <os/log.h>
#import <UIKit/UIAlertController.h>
#import "MADMutualExclusive.h"
#import <MADFoundation/NSError+MADOperationErrors.h>

static NSString * const TextYes = @"Yes";
static NSString * const TextNo = @"No";

@interface MADOperationPromptPolarQuestion ()

    @property (nonatomic, readwrite, assign) BOOL result;
    @property (nonatomic, copy) NSString *title;
    @property (nonatomic, copy) NSString *message;
    @property (nonatomic, weak) UIViewController *viewController;
    @property (nonatomic, readwrite, assign) BOOL alertDisplayed;

@end

@implementation MADOperationPromptPolarQuestion

- (void)dealloc {
    //os_log_info(OS_LOG_DEFAULT, "Dealloc %s", NSStringFromClass(self.class).UTF8String);
}

- (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
               viewController:(UIViewController * __weak)viewController {
    if (self = [super init]) {

        _viewController = viewController;
        _title = title.copy;
        _message = message.copy;
        _result = NO;
        self.identifier = self.hash;
        //MADMutualExclusiveCondition *condition = [MADMutualExclusiveCondition newMutualExclusiveConditionAlertMutex];
        //[self addCondition:condition];
        
    }
    return self;
}

- (BOOL)alertDisplayedAffirmed {
    return self.alertDisplayed && self.result;
}

- (BOOL)isAsynchronous {
    return YES;
}

- (void)execute {
    os_log_info(OS_LOG_DEFAULT, "Execute %s", NSStringFromClass(self.class).UTF8String);
    
    if (self.cancelled) {
        return [self finish];
    }

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle: self.title
                                                                             message: self.message
                                                                      preferredStyle: UIAlertControllerStyleAlert];
    
    MADOperationPromptPolarQuestion * __weak weakSelf = self;
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle: TextYes
                                                       style: UIAlertActionStyleDefault
                                                     handler: ^(UIAlertAction * _Nonnull action) {
        MADOperationPromptPolarQuestion * __strong sself = weakSelf;
        sself.result = YES;
        sself.alertDisplayed = YES;
        [sself performSelector:@selector(finish)];
    }];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle: TextNo
                                                           style: UIAlertActionStyleCancel
                                                         handler: ^(UIAlertAction * _Nonnull action) {
        MADOperationPromptPolarQuestion * __strong sself = weakSelf;
        sself.result = NO;
        sself.alertDisplayed = YES;
        NSError *error = [NSError errorWithDomain: NSStringFromClass([self class]) code: MADConditionFailed userInfo: nil];
        [sself performSelector:@selector(finishWithError:) withObject:error];
    }];
    
    [alertController addAction:actionOK];
    [alertController addAction:actionCancel];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        UIViewController *viewController = weakSelf.viewController;
        viewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [viewController presentViewController: alertController animated: YES completion: nil];
    }];
}

@end
