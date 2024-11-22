//
//  MADAlertControllerFeedback.h
//  MADFeedback
//
//  Created by Michael Thomason on 8/28/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Feedback_MADAlertControllerFeedback_h
#define MAD_Feedback_MADAlertControllerFeedback_h

#import <UIKit/UIAlertController.h>

typedef void(^MADAlertActionHandler)(UIAlertAction *);

@interface MADAlertControllerFeedback : UIAlertController

	+ (instancetype)newAlertControllerFeedbackWithHandler:(MADAlertActionHandler)handler
												   cancel:(MADAlertActionHandler)handlerCancel;

@end

#endif
