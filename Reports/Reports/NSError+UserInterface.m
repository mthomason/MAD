//
//  NSError+UserInterface.m
//  Reports
//
//  Created by Michael Thomason on 12/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "NSError+UserInterface.h"

@implementation NSError (UserInterface)

- (void)presentErrorToUser {
    
    NSString *continueButtonTitle = NSLocalizedString(MNSStringInterfaceButtonTitleContinue, MNSStringInterfaceContinueButtonTitleDescription);
    NSArray *otherButtonTitles = @[NSLocalizedString(MNSStringInterfaceButtonTitleAbort, MNSStringInterfaceButtonTitleAbortDesc)];

    [UIAlertView showAlertViewWithTitle:[self localizedDescription] message:[self localizedFailureReason] cancelButtonTitle:continueButtonTitle otherButtonTitle:otherButtonTitles onDismiss:^(int buttonIndex) {
        switch (buttonIndex) {
            case 0:             //Continue to do nothing.
                break;
            case 1:             //Abort application
                exit(0);
                break;
            default:
                break;
        }
        
    } onCancel:^{ }];

}

- (void)presentErrorToUserWithTryAgain:(void (^)(BOOL success))tryAgain {
    
    NSString *continueButtonTitle = NSLocalizedString(MNSStringInterfaceButtonTitleContinue, MNSStringInterfaceContinueButtonTitleDescription);
    NSArray *otherButtonTitles = @[NSLocalizedString(MNSStringInterfaceButtonTitleTryAgain, MNSStringInterfaceButtonTitleTryAgainDesc),
    NSLocalizedString(MNSStringInterfaceButtonTitleAbort, MNSStringInterfaceButtonTitleAbortDesc)];
    
    [UIAlertView showAlertViewWithTitle:[self localizedDescription] message:[self localizedFailureReason] cancelButtonTitle:continueButtonTitle otherButtonTitle:otherButtonTitles onDismiss:^(int buttonIndex) {
        switch (buttonIndex) {
            case 1:             //FIXME: Allow try again block.
                tryAgain(YES);
                break;
            case 2:             //Abort applicaiton
                exit(0);
                break;
            default:
                break;
        }
        
    } onCancel:^{ }];
    
}

- (void)presentErrorToUserWithTryAgain:(void (^)(BOOL success))tryAgain andCompletion:(void (^)(BOOL success))completion {
    
    NSString *continueButtonTitle = NSLocalizedString(MNSStringInterfaceButtonTitleContinue, MNSStringInterfaceContinueButtonTitleDescription);
    NSArray *otherButtonTitles = @[NSLocalizedString(MNSStringInterfaceButtonTitleTryAgain, MNSStringInterfaceButtonTitleTryAgainDesc),
                                    NSLocalizedString(MNSStringInterfaceButtonTitleAbort, MNSStringInterfaceButtonTitleAbortDesc)];
    
    [UIAlertView showAlertViewWithTitle:[self localizedDescription] message:[self localizedFailureReason] cancelButtonTitle:continueButtonTitle otherButtonTitle:otherButtonTitles onDismiss:^(int buttonIndex) {
        switch (buttonIndex) {
            case 0:             //Continue to do nothing.
                completion(YES);
                break;
            case 1:             //FIXME: Allow try again block.
                tryAgain(YES);
                break;
            case 2:             //Abort applicaiton
                exit(0);
                break;
            default:
                break;
        }
        
    } onCancel:^{ }];
    
}

@end