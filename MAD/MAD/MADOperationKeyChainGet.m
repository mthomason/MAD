//
//  MADOperationKeyChainGet.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import "MADOperationKeyChainGet.h"
#import "madlog.h"

#import <MADFoundation/MADKeyChain.h>

#import <CoreFoundation/CFData.h>

#import <Foundation/NSString.h>
#import <Foundation/NSError.h>

#import <Security/SecItem.h>

@interface MADOperationKeyChainGet ()

	@property (nonatomic, readwrite, copy) NSString *key;
	@property (nonatomic, readwrite, copy) NSString *keyDescription;
	@property (atomic, readwrite, copy) NSString *value;
	@property (atomic, readwrite, assign) BOOL success;

@end

@implementation MADOperationKeyChainGet

- (void)dealloc { }

- (instancetype)initWithKey:(NSString *)key withDescription:(NSString *)description {
	if (self = [super init]) {
		_key = key.copy;
		_success = NO;
		_keyDescription = description.copy;
	}
	return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
	if (self.cancelled) return [self finish];

	CFDataRef queryData = NULL;
	NSDictionary *queryDefination = [MADKeyChain queryDefination: self.key
												 withDescription: self.keyDescription];
	CFDictionaryRef queryDefinationC = (__bridge_retained CFDictionaryRef)queryDefination;
	OSStatus queryStatus = SecItemCopyMatching(queryDefinationC, (CFTypeRef *)&queryData);
	CFRelease(queryDefinationC);
	
	if (self.cancelled) return [self finish];

	if (queryData == NULL) {
		[self finishWithErrorStatus:queryStatus];
		return;

	}
	NSData *resultData = (__bridge_transfer NSData *)queryData;

	NSString *result;
	
	switch (queryStatus) {
		case errSecSuccess:
			
			result = [[NSString alloc] initWithData: resultData
										   encoding: NSUTF8StringEncoding];
			self.value = result;
			self.success = YES;
			[self finish];
			break;
			
		default:

			self.value = nil;
			break;
	}
	if (self.success) {
		[self finish];
	} else {
		[self finishWithErrorStatus:queryStatus];
	}
}

- (void)finishWithErrorStatus:(OSStatus)status {
	NSError *error = [NSError errorWithDomain: NSStringFromClass([self class])
										 code: status
									 userInfo: nil];
	os_log_error(GetMadLog(), "%s: %@", __PRETTY_FUNCTION__, error);
	[self finishWithError:error];
}

@end
