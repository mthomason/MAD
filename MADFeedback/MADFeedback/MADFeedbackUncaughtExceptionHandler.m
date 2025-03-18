//
//  MADFeedbackUncaughtExceptionHandler.m
//  MADFeedback
//
//  Created by Michael Thomason on 8/28/15.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADFeedbackUncaughtExceptionHandler.h"
#import <UIKit/UIAlertView.h>
#import <libkern/OSAtomic.h>
#import <execinfo.h>

NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
NSString * const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";
NSString * const UncaughtExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";

volatile int32_t UncaughtExceptionCount = 0;
const int32_t UncaughtExceptionMaximum = 10;

const NSInteger UncaughtExceptionHandlerSkipAddressCount = 4;
const NSInteger UncaughtExceptionHandlerReportAddressCount = 5;

@implementation MADFeedbackUncaughtExceptionHandler

+ (NSArray *)backtrace {
	void *callstack[128];
	int frames = backtrace(callstack, 128);
	char **strs = backtrace_symbols(callstack, frames);
	
	NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:(unsigned int)frames];
	for (int i = UncaughtExceptionHandlerSkipAddressCount; i < UncaughtExceptionHandlerSkipAddressCount + UncaughtExceptionHandlerReportAddressCount; i++) {
		[backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
	}
	
	free(strs);
	
	return backtrace;
}

- (void)alertView:(UIAlertView *)anAlertView clickedButtonAtIndex:(NSInteger)anIndex {
	if (anIndex == 0) { self.dismissed = YES; }
}

- (void)validateAndSaveCriticalApplicationData {
	
}

- (void)handleException:(NSException *)exception {
	[self validateAndSaveCriticalApplicationData];
	
	NSString *format = NSLocalizedString(@"You can try to continue but the application may be unstable.\n\n"
										 @"Debug details follow:\n%@\n%@", nil);
	NSString *message = [NSString stringWithFormat:format, exception.reason,
						 [exception.userInfo objectForKey:UncaughtExceptionHandlerAddressesKey]];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Unhandled exception", nil)
													message: message
												   delegate: self
										  cancelButtonTitle: NSLocalizedString(@"Quit", nil)
										  otherButtonTitles: NSLocalizedString(@"Continue", nil), nil];
	[alert show];
	
	CFRunLoopRef runLoop = CFRunLoopGetCurrent();
	CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);
	
	while (!self.dismissed) {
		for (NSString *mode in (__bridge NSArray *)allModes) {
			CFRunLoopRunInMode((CFStringRef)mode, 0.001, NO);
		}
	}
	
	CFRelease(allModes);
	
	NSSetUncaughtExceptionHandler(NULL);
	signal(SIGABRT, SIG_DFL);
	signal(SIGILL, SIG_DFL);
	signal(SIGSEGV, SIG_DFL);
	signal(SIGFPE, SIG_DFL);
	signal(SIGBUS, SIG_DFL);
	signal(SIGPIPE, SIG_DFL);
	
	if ([exception.name isEqualToString:UncaughtExceptionHandlerSignalExceptionName]) {
		kill(getpid(), [[exception.userInfo objectForKey:UncaughtExceptionHandlerSignalKey] intValue]);
	} else {
		[exception raise];
	}
}

@end

static void MADUncaughtExceptionHandler(NSException *exception) __attribute__((unused));
static void MADUncaughtExceptionHandler(NSException *exception) {
	int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
	if (exceptionCount > UncaughtExceptionMaximum) {
		return;
	}
	
	NSArray *callStack = [MADFeedbackUncaughtExceptionHandler backtrace];
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:exception.userInfo];
	[userInfo setObject: callStack
				 forKey: UncaughtExceptionHandlerAddressesKey];
	
	NSException *exceptionRepackaged = [NSException exceptionWithName: exception.name reason: exception.reason userInfo: userInfo];
	MADFeedbackUncaughtExceptionHandler *eh = [[MADFeedbackUncaughtExceptionHandler alloc] init];
	[eh performSelectorOnMainThread:@selector(handleException:) withObject: exceptionRepackaged waitUntilDone: YES];
}

void MADSignalHandler(int signal);
void MADSignalHandler(int signal) {
	int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
	if (exceptionCount > UncaughtExceptionMaximum) {
		return;
	}
	
	NSNumber *signalN = [NSNumber numberWithInt:signal];
	
	NSMutableDictionary *userInfo =
	[NSMutableDictionary dictionaryWithObject: signalN
									   forKey: UncaughtExceptionHandlerSignalKey];
	
	NSArray *callStack = [MADFeedbackUncaughtExceptionHandler backtrace];
	[userInfo setObject: callStack
				 forKey: UncaughtExceptionHandlerAddressesKey];
	
	NSString *format = NSLocalizedString(@"Signal %d was raised.", nil);
	NSString *reason = [NSString stringWithFormat:format, signal];
	NSDictionary *uinfo = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:signal]
													  forKey: UncaughtExceptionHandlerSignalKey];
	NSException *exc = [NSException exceptionWithName: UncaughtExceptionHandlerSignalExceptionName
											   reason: reason
											 userInfo: uinfo];
	MADFeedbackUncaughtExceptionHandler *eh = [[MADFeedbackUncaughtExceptionHandler alloc] init];
	[eh performSelectorOnMainThread: @selector(handleException:)
						 withObject: exc
					  waitUntilDone: YES];
}

/*
void MADUncaughtExceptionHandlerInstaller() {
	NSSetUncaughtExceptionHandler(&MADUncaughtExceptionHandler);
	signal(SIGABRT, MADSignalHandler);
	signal(SIGILL, MADSignalHandler);
	signal(SIGSEGV, MADSignalHandler);
	signal(SIGFPE, MADSignalHandler);
	signal(SIGBUS, MADSignalHandler);
	signal(SIGPIPE, MADSignalHandler);
}
*/

