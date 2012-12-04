//
//  NSError+UserInterface.h
//  Reports
//
//  Created by Michael Thomason on 12/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIAlertView+Blocks.h"
#import "Constants.h"

@interface NSError (UserInterface)

- (void)presentErrorToUser;
- (void)presentErrorToUserWithTryAgain:(void (^)(BOOL success))tryAgain;
- (void)presentErrorToUserWithTryAgain:(void (^)(BOOL success))tryAgain andCompletion:(void (^)(BOOL success))completion;

@end