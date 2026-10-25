//
//  MADOperationArchiveData.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADOperationArchiveData.h"
#import <MADFoundation/madlog.h>
#import <Foundation/NSData.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSException.h>
#import <Foundation/NSError.h>
#import <Foundation/NSKeyedArchiver.h>

@interface MADOperationArchiveData ()
	@property (nonatomic, copy) NSURL *url;
	@property (nonatomic, strong) id <NSCoding> object;
@end

@implementation MADOperationArchiveData

- (instancetype)initWithURL:(NSURL *)url andObject:(id <NSCoding>)object {
	if (self = [super init]) {
		_url = url.copy;
		self.object = object;
	}
	return self;
}

- (BOOL)isAsynchronous {
	return YES;
}

- (void)start {

	if (self.cancelled) {
		[self finish];
	}
	
	BOOL success = NO;
	NSError *finalError = nil;

	@try {

		id <NSCoding> obj = self.object;
		NSError *errorArchiver = nil;
		NSData *d = [NSKeyedArchiver archivedDataWithRootObject:obj requiringSecureCoding:YES error:&errorArchiver];
		if (errorArchiver != nil) {
			finalError = [errorArchiver copy];
			os_log_error(GetDesignerLog(), "%s: Error archiving object: %@", __PRETTY_FUNCTION__, errorArchiver);
		}

		NSError *writingError = nil;
		success = [d writeToURL:self.url options:NSDataWritingAtomic error:&writingError];
		if (writingError != nil) {
			finalError = [writingError copy];
			os_log_error(GetDesignerLog(), "%s: Error writing data to file: %@", __PRETTY_FUNCTION__, writingError);
		}
		self.object = nil;
		
	} @catch (NSException *exception) {
		
	} @finally {

		if (success) {
			[self finish];
		} else {
			[self finishWithError:finalError];
		}

	}

}

@end
