//
//  MADOperationKeyChainPut.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationKeyChainPut.h"
#import "madlog.h"

#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADKeyChain.h>

#import <Foundation/NSString.h>
#import <Foundation/NSError.h>
#import <Foundation/NSArray.h>

#import <security/SecBase.h>

static const short StatusNotFound = 35;
static NSString * const ErrorDomain = @"MADKCP";

@interface MADOperationKeyChainPut ()

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *keyDescription;

@end

@implementation MADOperationKeyChainPut

- (void)dealloc { }

- (instancetype)initWithKey:(NSString *)key description:(NSString *)description {
	if (self = [super init]) {
		_key = key.copy;
		_keyDescription = description.copy;
	}
	return self;
}

- (void)execute {
	if (self.cancelled) return [self finish];

	NSString *valueToWrite = nil;
	
	// Search the operations dependencies for the value to write.
	//
	NSArray<__kindof NSOperation *> *dependencies = self.dependencies;
	for (NSOperation *operation in dependencies) {
	
		if ([operation conformsToProtocol:@protocol(MADKeyChainKeyValueProtocol)]) {
			valueToWrite = [((NSObject <MADKeyChainKeyValueProtocol> *)operation) valueForKey:self.key];
			if (valueToWrite != nil) {
				break;
			}
		}
	}
	
	if (self.cancelled) return [self finish];

	if (valueToWrite != nil) {
		OSStatus status = [MADKeyChain saveToken: valueToWrite
										 forKey: self.key
								withDescription: self.keyDescription];
		if (status == errSecSuccess) {
			[self finish];
		} else {
			NSError *error = [NSError errorWithDomain: ErrorDomain code: status userInfo: nil];
			[self finishWithError:error];
		}
		
	} else {
		NSError *error = [NSError errorWithDomain: ErrorDomain code: StatusNotFound userInfo: nil];
		[self finishWithError:error];
	}
}

@end
