//
//  MADDirectoryMonitor.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDirectoryMonitor.h"
#import "MADDirectoryMonitorProtocol.h"
#import "madlog.h"

#import <Foundation/NSURL.h>
#import <sys/unistd.h>
#import <sys/fcntl.h>
#import <dispatch/dispatch.h>

const char * MADQueueFileSystemWatcher = "com.everydayapps.mad.filesystem.watcher";
static const int NotListening = -1;

@interface MADDirectoryMonitor ()
	@property (nonatomic, copy)     NSURL *URL;
	@property (nonatomic, strong)   dispatch_queue_t directoryMonitorQueue;
	@property (nonatomic, strong)   dispatch_source_t directoryMonitorSource;
@end

@implementation MADDirectoryMonitor {
	int _fileDescriptor;
}

#pragma mark - Initializers

- (instancetype)initWithURL:(NSURL *)URL {

	if (self = [super init]) {
		_URL = URL.copy;
		_fileDescriptor = NotListening;
	}
	
	return self;
}

#pragma mark - Monitoring

- (void)startMonitoring {

	if (self.directoryMonitorSource == nil && _fileDescriptor == NotListening) {
	
		const char *path = [self.URL.path cStringUsingEncoding:NSUTF8StringEncoding];
		_fileDescriptor = open(path, O_EVTONLY);

		if (_fileDescriptor < 0) return;
		
		id directoryMonitorQueue = dispatch_queue_create(MADQueueFileSystemWatcher,
														 DISPATCH_QUEUE_CONCURRENT);
		self.directoryMonitorQueue = directoryMonitorQueue;
		
		unsigned long mask = DISPATCH_VNODE_DELETE | DISPATCH_VNODE_EXTEND |
							 DISPATCH_VNODE_RENAME | DISPATCH_VNODE_ATTRIB | DISPATCH_VNODE_WRITE;
		
		id directoryMonitorSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
														   (uintptr_t)_fileDescriptor,
														   mask,
														   self.directoryMonitorQueue);
		self.directoryMonitorSource = directoryMonitorSource;
		
		MADDirectoryMonitor __weak *weakself = self;

		dispatch_source_set_event_handler(self.directoryMonitorSource, ^{
			
			MADDirectoryMonitor *sself = weakself;
			dispatch_source_proc_flags_t flags = dispatch_source_get_data(sself.directoryMonitorSource);
			switch (flags) {
				case DISPATCH_VNODE_DELETE:
					os_log_debug(GetFileManagerLog(), "Delete event.");
					break;
				case DISPATCH_VNODE_RENAME:
					os_log_debug(GetFileManagerLog(), "Rename event.");
					break;
				case DISPATCH_VNODE_EXTEND:
					os_log_debug(GetFileManagerLog(), "Extend event.");
					break;
				case DISPATCH_VNODE_ATTRIB:
					os_log_debug(GetFileManagerLog(), "Attribute update event.");
					break;
				case DISPATCH_VNODE_WRITE:
					os_log_debug(GetFileManagerLog(), "Write event.");
					break;
				default:
					os_log_debug(GetFileManagerLog(), "Untracked event.");
					break;
			}
			[sself.delegate directoryMonitorDidObserveChange:sself];
			
		});
		
		dispatch_source_set_cancel_handler(self.directoryMonitorSource, ^{
			MADDirectoryMonitor *sself = weakself;
			close(sself->_fileDescriptor);
			sself->_fileDescriptor = NotListening;
			sself.directoryMonitorSource = nil;
		});
		dispatch_resume(self.directoryMonitorSource);
	}
}

- (void)stopMonitoring {
	if (self.directoryMonitorSource != nil) {
		dispatch_source_cancel(self.directoryMonitorSource);
	}
}

- (id)debugQuickLookObject {
	NSMutableString *debug = [[NSMutableString alloc] init];
	NSString *classname = NSStringFromClass([self class]);
	NSString *url = _URL.absoluteString;
	id uppercaseClassname = [classname uppercaseString];
	[debug appendFormat:@"--%@--\n", uppercaseClassname];
	[debug appendFormat:@"\tDirectory to monitor: %@\n", url];
	[debug appendFormat:@"\tFile descriptor: %d\n", _fileDescriptor];
	return debug;
}

@end
