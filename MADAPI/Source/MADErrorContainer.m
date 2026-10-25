//
//  MADErrorContainer.m
//  MAD
//
//  Created by Michael Thomason on 8/16/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADErrorContainer.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSDateFormatter.h>

static NSString * const MADErrorContainerError  = @"e";
static NSString * const MADErrorContainerDate   = @"d";

@interface MADErrorContainer ()

@property (nonatomic, strong) NSMutableArray <NSDictionary *> *errors;

@end

@implementation MADErrorContainer

- (instancetype)init {
	if (self = [super init]) {
		NSMutableArray *errors = [NSMutableArray new];
		self.errors = errors;
	}
	return self;
}

- (NSUInteger)count {
	return self.errors.count;
}

- (void)addError:(NSError *)error {
	NSError *errorCopy = error.copy;
	NSDictionary *errorHolder = @{
		MADErrorContainerError    : errorCopy,
		MADErrorContainerDate     : [NSDate date]
	};
	[self.errors addObject:errorHolder];
}

- (NSString *)errorLog {
	return [self errorLogWithFormatString:@"%@ - \t\t%@\n\t\t\t\t%@\n"];
}

- (NSString *)errorLogCompact {
	return [self errorLogWithFormatString:@"%@ - %@ - %@\n"];
}

- (NSString *)errorLogWithFormatString:(NSString *)formatString {
	NSMutableString *result = [NSMutableString new];
	for (NSDictionary *errorHolder in self.errors) {
		NSDate * _Nonnull date = (errorHolder[MADErrorContainerDate] != nil) ?
								(id _Nonnull)errorHolder[MADErrorContainerDate] : [NSDate date];
		NSString *dateString = [NSDateFormatter localizedStringFromDate: date
															  dateStyle: NSDateFormatterShortStyle
															  timeStyle: NSDateFormatterShortStyle];
		NSError *error = errorHolder[MADErrorContainerError];
		NSString *errorString = [[NSString alloc] initWithFormat:formatString,
																 dateString,
																 error.localizedFailureReason,
																 error.localizedDescription];
		[result appendString:errorString];
	}
	return result;
}

- (NSArray <__kindof NSError *> *)allObjects {
	NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:self.errors.count];
	for (NSDictionary *containers in self.errors) {
		NSError *error = ((NSError *)containers[@"e"]).copy;
		[results addObject:error];
	}
	return results;
}

- (void)addErrorsFromContainer:(MADErrorContainer *)additionalErrorContainer {
	NSArray *adderrs = [additionalErrorContainer allObjects];
	for (NSError *err in adderrs) {
		@autoreleasepool {
			[self addError:err];
		}
	}
}

@end
