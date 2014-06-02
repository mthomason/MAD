//
//  NSError+UserInterface.h
//  Reports
//
//  Created by Michael Thomason on 12/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_NSError_UserInterface_h
#define Reports_NSError_UserInterface_h

#import <Foundation/Foundation.h>

@interface NSError (UserInterface)

- (void)presentErrorToUser;
- (void)presentErrorToUserWithContinue:(void (^)(BOOL success))tryAgain;
- (void)presentErrorToUserWithTryAgain:(void (^)(BOOL success))tryAgain andCompletion:(void (^)(BOOL success))completion;
- (void)presentErrorToUserWithCompletion:(void (^)(BOOL success))completion;

+ (NSDictionary *)userInfoWithTitle:(NSString *)title andMessage:(NSString *)message;

@end

#endif
