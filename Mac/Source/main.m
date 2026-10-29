//
//  main.m
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import <Cocoa/Cocoa.h>
#import "MADMacAppDelegate.h"

int main(int argc, const char * _Nonnull argv[]) {
	@autoreleasepool {
		NSApplication *app = [NSApplication sharedApplication];
		[app setActivationPolicy:NSApplicationActivationPolicyRegular];
		MADMacAppDelegate *delegate = [[MADMacAppDelegate alloc] init];
		app.delegate = delegate;
		[app run];
	}
	return EXIT_SUCCESS;
}
