//
//  NSError+UserInterface.h
//  Reports
//
//  Created by Michael Thomason on 12/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_NSError_UserInterface_h
#define Reports_NSError_UserInterface_h

#import <UIKit/UIKit.h>

@interface NSError (UserInterface)

- (void)presentErrorOnViewController:(UIViewController *)viewController;
+ (NSDictionary *)userInfoWithTitle:(NSString *)title andMessage:(NSString *)message;

@end

#endif
