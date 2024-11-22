//
//  MADFileInfo.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADFileInfo.h"
#import "MADFileUtilities.h"
#import <Foundation/NSURL.h>
#import <Foundation/NSFileManager.h>
#import <dispatch/dispatch.h>

static const char * QueueFileInfo = "com.everydayapps.mad.fileinfo";

@interface MADFileInfo ()
	@property (nonatomic, strong, readonly) dispatch_queue_t fetchQueue;
@end

@implementation MADFileInfo {
	dispatch_queue_t _fetchQueue;
}

#pragma mark - Initialization

- (instancetype)initWithURL:(NSURL *)URL {
	
	if (self = [super init]) {
		_URL = URL.copy;
	}
	
	return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
	id copy = [[[self class] alloc] initWithURL:self.URL];
	return copy;
}

#pragma mark - Fetch Methods

- (dispatch_queue_t)fetchQueue {
	if (_fetchQueue == nil) {
		_fetchQueue = dispatch_queue_create(QueueFileInfo, DISPATCH_QUEUE_SERIAL);
	}
	return _fetchQueue;
}

- (void)fetchInfoWithCompletionHandler:(void (^)(void))completion {
	dispatch_async(self.fetchQueue, ^{
		completion();
		return;
	});
}

#pragma mark - Property Overrides

- (NSString *)name {
	NSString *path = self.URL.path;
	if (!path) return @"";
	NSString *displayName = [[NSFileManager defaultManager] displayNameAtPath: path];
	return displayName.stringByDeletingPathExtension;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
	if (![object isKindOfClass:[MADFileInfo class]]) return NO;
	return [self.URL.absoluteURL isEqual:((MADFileInfo *)object).URL.absoluteURL];

}

- (id)debugQuickLookObject {
	NSMutableString *debug = [[NSMutableString alloc] init];
	NSString *classname = NSStringFromClass([self class]);
	NSString *absoluteString = _URL.absoluteString.copy;
	NSString *name = self.name.copy;
	id uppercaseClassname = [classname uppercaseString];
	[debug appendFormat:@"--%@--\n", uppercaseClassname];
	[debug appendFormat:@"\tName: %@\n", name];
	[debug appendFormat:@"\tUrl:  %@\n", absoluteString];
	return debug;
}

@end
