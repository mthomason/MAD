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

    MTAlertView *alertView = [[MTAlertView alloc] initWithTitle: [self localizedDescription]
                                                        message: [self localizedFailureReason]
                                              cancelButtonTitle: continueButtonTitle
                                               otherButtonTitle: otherButtonTitles onDismiss:^(NSInteger buttonIndex) {
                                                   
                                                   exit(0);
                                               
                                               } onCancel:nil];
    [alertView show];
    [alertView autorelease];

}

- (void)presentErrorToUserWithTryAgain:(void (^)(BOOL tryagain))tryAgain {
    NSString *continueButtonTitle = NSLocalizedString(MNSStringInterfaceButtonTitleContinue, MNSStringInterfaceContinueButtonTitleDescription);
    NSArray *otherButtonTitles = @[NSLocalizedString(MNSStringInterfaceButtonTitleTryAgain, MNSStringInterfaceButtonTitleTryAgainDesc),
    NSLocalizedString(MNSStringInterfaceButtonTitleAbort, MNSStringInterfaceButtonTitleAbortDesc)];
    
    MTAlertView *alertView = [[MTAlertView alloc] initWithTitle: [self localizedDescription]
                                                        message: [self localizedFailureReason]
                                              cancelButtonTitle: continueButtonTitle
                                               otherButtonTitle: otherButtonTitles onDismiss:^(NSInteger buttonIndex) {
                                                   switch (buttonIndex) {
                                                       case 0:
                                                           tryAgain(YES);
                                                           break;
                                                       case 1:             //Abort applicaiton
                                                           exit(0);
                                                           break;
                                                       default:
                                                           break;
                                                   }
                                               } onCancel:^{
                                                   tryAgain(NO);
                                               }];
    [alertView show];
    [alertView autorelease];
}

- (void)presentErrorToUserWithTryAgain:(void (^)(BOOL tryagain))tryAgain andCompletion:(void (^)(BOOL success))completion {
    
    NSString *continueButtonTitle = NSLocalizedString(MNSStringInterfaceButtonTitleContinue, MNSStringInterfaceContinueButtonTitleDescription);
    NSArray *otherButtonTitles = @[NSLocalizedString(MNSStringInterfaceButtonTitleTryAgain, MNSStringInterfaceButtonTitleTryAgainDesc),
                                    NSLocalizedString(MNSStringInterfaceButtonTitleAbort, MNSStringInterfaceButtonTitleAbortDesc)];
    
    MTAlertView *alertView = [[MTAlertView alloc] initWithTitle: [self localizedDescription]
                                                        message: [self localizedFailureReason]
                                              cancelButtonTitle: continueButtonTitle
                                               otherButtonTitle: otherButtonTitles onDismiss:^(NSInteger buttonIndex) {

                                                   switch (buttonIndex) {
                                                       case 0:
                                                           tryAgain(YES);
                                                           break;
                                                       case 1:             //Abort applicaiton
                                                           exit(0);
                                                           break;
                                                       default:
                                                           break;
                                                   }

                                               } onCancel:^(){
                                                   completion(YES);
                                               }];
    [alertView show];
    [alertView autorelease];
}

- (void)presentErrorToUserWithCompletion:(void (^)(BOOL success))completion {
    
    NSString *continueButtonTitle = NSLocalizedString(MNSStringInterfaceButtonTitleContinue, MNSStringInterfaceContinueButtonTitleDescription);
    NSArray *otherButtonTitles = @[NSLocalizedString(MNSStringInterfaceButtonTitleAbort, MNSStringInterfaceButtonTitleAbortDesc)];
    MTAlertView *alertView = [[MTAlertView alloc] initWithTitle: [self localizedDescription]
                                                        message: [self localizedFailureReason]
                                              cancelButtonTitle: continueButtonTitle
                                               otherButtonTitle: otherButtonTitles
                                                      onDismiss:^(NSInteger buttonIndex) {

                                                          exit(0);

                                                      } onCancel:^(){

                                                          completion(YES);

                                                      }];
    [alertView show];
    [alertView autorelease];
}

@end