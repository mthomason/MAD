//
//  UIAlertController+Feedback.h
//  MADFeedback
//
//  Created by Michael Thomason on 8/28/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertController (Feedback)

+ (instancetype)solicateFeedbackWithHandler:(void (^)(UIAlertAction *action))handler
                                     cancel:(void (^)(UIAlertAction *action))handlerCancel;

@end
