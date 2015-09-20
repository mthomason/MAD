//
//  MADFeedbackUncaughtExceptionHandler.h
//  MADFeedback
//
//  Created by Michael Thomason on 8/28/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <libkern/OSAtomic.h>
#import <execinfo.h>

@interface MADFeedbackUncaughtExceptionHandler : NSObject;

@property (nonatomic, assign) BOOL dismissed;

@end

//void MADUncaughtExceptionHandlerInstaller();
