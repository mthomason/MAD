//
//  MADDirectoryMonitor.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDirectoryMonitor.h"
#import "MADDirectoryMonitorProtocol.h"
#import <MADFoundation/madlog.h>

#import <Foundation/NSURL.h>
#import <sys/unistd.h>
#import <sys/fcntl.h>
#import <dispatch/dispatch.h>
#if !__APPLE__
#include <sys/inotify.h>
#endif

const char * MADQueueFileSystemWatcher = "com.everydayapps.mad.filesystem.watcher";
static const int NotListening = -1;

@interface MADDirectoryMonitor ()
	@property (nonatomic, copy)     NSURL *URL;
#if __APPLE__
	@property (nonatomic, strong)   dispatch_queue_t directoryMonitorQueue;
	@property (nonatomic, strong)   dispatch_source_t directoryMonitorSource;
#else
	// Dispatch objects are plain C pointers off Apple (os/object.h declines
	// ObjC support outside Darwin), so ARC cannot own them.
	@property (nonatomic, assign)   dispatch_queue_t directoryMonitorQueue;
	@property (nonatomic, assign)   dispatch_source_t directoryMonitorSource;
#endif
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
#if __APPLE__
		_fileDescriptor = open(path, O_EVTONLY);
#else
		// Darwin watches a directory through kqueue (DISPATCH_SOURCE_TYPE_VNODE,
		// O_EVTONLY); Linux's equivalent is an inotify descriptor drained by a
		// dispatch read source.  Closing the descriptor removes the watch.
		_fileDescriptor = inotify_init1(IN_NONBLOCK);
#endif

		if (_fileDescriptor < 0) return;

		dispatch_queue_t directoryMonitorQueue = dispatch_queue_create(MADQueueFileSystemWatcher,
																	   DISPATCH_QUEUE_CONCURRENT);
		self.directoryMonitorQueue = directoryMonitorQueue;

#if __APPLE__
		unsigned long mask = DISPATCH_VNODE_DELETE | DISPATCH_VNODE_EXTEND |
							 DISPATCH_VNODE_RENAME | DISPATCH_VNODE_ATTRIB | DISPATCH_VNODE_WRITE;

		dispatch_source_t directoryMonitorSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
																		  (uintptr_t)_fileDescriptor,
																		  mask,
																		  self.directoryMonitorQueue);
#else
		uint32_t mask = IN_CREATE | IN_DELETE | IN_MOVED_FROM | IN_MOVED_TO |
						IN_ATTRIB | IN_MODIFY | IN_DELETE_SELF | IN_CLOSE_WRITE;
		if (inotify_add_watch(_fileDescriptor, path, mask) < 0) {
			close(_fileDescriptor);
			_fileDescriptor = NotListening;
			return;
		}
		dispatch_source_t directoryMonitorSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ,
																		  (uintptr_t)_fileDescriptor,
																		  0,
																		  self.directoryMonitorQueue);
#endif
		self.directoryMonitorSource = directoryMonitorSource;

		MADDirectoryMonitor __weak *weakself = self;

		dispatch_source_set_event_handler(self.directoryMonitorSource, ^{

			MADDirectoryMonitor *sself = weakself;
#if __APPLE__
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
#else
			// Drain the queued inotify events; the read source is level-triggered,
			// so one read of the whole buffer is enough to re-arm it.
			char buffer[4096] __attribute__((aligned(__alignof__(struct inotify_event))));
			ssize_t length = read(sself->_fileDescriptor, buffer, sizeof(buffer));
			if (length <= 0) return;
			os_log_debug(GetFileManagerLog(), "inotify event.");
#endif
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
