//
//  MADPromptOperationPolarQuestion.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADPromptOperationPolarQuestion.h"
#import <UIKit/UIAlertController.h>
#import "MADMutualExclusive.h"
#import "MADAlertController.h"

static NSString * const TextYes = @"Yes";
static NSString * const TextNo = @"No";

@interface MADPromptOperationPolarQuestion ()
    <MADAlertControllerAlertRemovedProtocol>

    @property (nonatomic, readwrite, assign) bool result;
    @property (nonatomic, copy) NSString *title;
    @property (nonatomic, copy) NSString *message;
    @property (nonatomic, weak) UIViewController *viewController;
    @property (nonatomic, readwrite, assign) bool alertDisplayed;

@end

@implementation MADPromptOperationPolarQuestion

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message
               viewController:(UIViewController * __weak)viewController {
    if (self = [super init]) {
        _viewController = viewController;
        _title = title.copy;
        _message = message.copy;
        _result = false;
        [self addCondition:[MADMutualExclusiveCondition alertMutex]];
        
    }
    return self;
}

- (void)execute {

    MADAlertController *alertController = [MADAlertController alertControllerWithTitle: self.title message: self.message
                                                                        preferredStyle: UIAlertControllerStyleAlert];
    alertController.madAlertControllerAlertRemovedDelegate = self;
    
    MADPromptOperationPolarQuestion * __weak weakSelf = self;
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle: TextYes
                                                       style: UIAlertActionStyleDefault
                                                     handler: ^(UIAlertAction * _Nonnull action) {
                                                         MADPromptOperationPolarQuestion * __strong sself = weakSelf;
                                                         sself.result = true;
                                                         sself.alertDisplayed = true;
                                                         [sself performSelectorInBackground:@selector(finish) withObject:nil];
                                                     }];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle: TextNo
                                                           style: UIAlertActionStyleCancel
                                                         handler: ^(UIAlertAction * _Nonnull action) {
                                                             MADPromptOperationPolarQuestion * __strong sself = weakSelf;
                                                             sself.result = false;
                                                             sself.alertDisplayed = true;
                                                             [sself performSelectorInBackground:@selector(finish) withObject:nil];
                                                         }];
    
    [alertController addAction:actionOK];
    [alertController addAction:actionCancel];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        UIViewController *viewController = self.viewController;
        viewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [viewController presentViewController: alertController animated: YES completion: nil];
    }];
}

#pragma mark - MADAlertControllerAlertRemovedProtocol

- (void)alertControllerDidDisappear:(MADAlertController *)alertController {
    alertController.madAlertControllerAlertRemovedDelegate = nil;
    //[self finish];
}

@end
