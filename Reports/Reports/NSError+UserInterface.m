//
//  NSError+UserInterface.m
//  Reports
//
//  Created by Michael Thomason on 12/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "NSError+UserInterface.h"

typedef void (^MTBlockErrorDismiss)(NSInteger buttonIndex);

@implementation NSError (UserInterface)

- (void)presentErrorToUser {
    
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", @"Cancel button title");
    //NSString *continueButtonTitle = NSLocalizedString(MNSStringInterfaceButtonTitleContinue, MNSStringInterfaceContinueButtonTitleDescription);
    //NSString *abortButtonTitle = NSLocalizedString(MNSStringInterfaceButtonTitleAbort, MNSStringInterfaceButtonTitleAbortDesc);
 
    MTBlockErrorDismiss dismissBlock = ^(NSInteger buttonIndex) {
        
        switch (buttonIndex) {
            case 0:
                break;
            case 1:
                exit(0);
                break;
            default:
                break;
        }
        
    };
    
    MTAlertView *alertView = [[MTAlertView alloc] initWithTitle: [self localizedDescription]
                                                        message: [self localizedFailureReason]
                                              cancelButtonTitle: cancelButtonTitle
                                               otherButtonTitle: nil
                                                      onDismiss: dismissBlock
                                                       onCancel: nil];
    [alertView show];
    [alertView autorelease];

}

- (void)presentErrorToUserWithContinue:(void (^)(BOOL tryagain))completion {
    NSString *continueButtonTitle = NSLocalizedString(MNSStringInterfaceButtonTitleContinue, MNSStringInterfaceContinueButtonTitleDescription);
    NSArray *otherButtonTitles = @[NSLocalizedString(MNSStringInterfaceButtonTitleTryAgain, MNSStringInterfaceButtonTitleTryAgainDesc)/*,
    NSLocalizedString(MNSStringInterfaceButtonTitleAbort, MNSStringInterfaceButtonTitleAbortDesc)*/];
    
    MTAlertView *alertView = [[MTAlertView alloc] initWithTitle: [self localizedDescription]
                                                        message: [self localizedFailureReason]
                                              cancelButtonTitle: continueButtonTitle
                                               otherButtonTitle: otherButtonTitles onDismiss:^(NSInteger buttonIndex) {
                                                   switch (buttonIndex) {
                                                       case 0:
                                                           completion(YES);
                                                           break;
                                                       case 1:             //Abort applicaiton
                                                           completion(NO);
                                                           exit(0);
                                                           break;
                                                       default:
                                                           completion(NO);
                                                           break;
                                                   }
                                               } onCancel:^{
                                                   completion(NO);
                                               }];
    [alertView show];
    [alertView autorelease];
}

- (void)presentErrorToUserWithTryAgain:(void (^)(BOOL tryagain))tryAgain andCompletion:(void (^)(BOOL success))completion {
    
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", @"Cancel button title");
    NSString *continueButtonTitle = NSLocalizedString(MNSStringInterfaceButtonTitleContinue, MNSStringInterfaceContinueButtonTitleDescription);
    NSArray *otherButtonTitles = @[continueButtonTitle, NSLocalizedString(MNSStringInterfaceButtonTitleTryAgain, MNSStringInterfaceButtonTitleTryAgainDesc)];
    
    MTAlertView *alertView = [[MTAlertView alloc] initWithTitle: [self localizedDescription]
                                                        message: [self localizedFailureReason]
                                              cancelButtonTitle: cancelButtonTitle
                                               otherButtonTitle: otherButtonTitles onDismiss:^(NSInteger buttonIndex) {

                                                   switch (buttonIndex) {
                                                       case 0:
                                                           break;
                                                       case 1:
                                                           tryAgain(YES);
                                                           break;
                                                       case 2:             //Abort applicaiton
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

+ (NSDictionary *)userInfoWithTitle:(NSString *)title andMessage:(NSString *)message {
    return @{NSLocalizedDescriptionKey :         title,
             NSLocalizedFailureReasonErrorKey :  message};
    
}

@end