//
//  MADFeedbackUncaughtExceptionHandler.h
//  MADFeedback
//
//  Created by Michael Thomason on 8/28/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Feedback_MADFeedbackUncaughtExceptionHandler_h
#define MAD_Feedback_MADFeedbackUncaughtExceptionHandler_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <libkern/OSAtomic.h>
#import <execinfo.h>

@interface MADFeedbackUncaughtExceptionHandler : NSObject;

    @property (nonatomic, assign) BOOL dismissed;

@end

#endif
