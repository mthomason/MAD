//
//  MADDirectoryMonitor.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADDirectoryMonitor.h"
#import <Foundation/NSURL.h>
#import <dispatch/dispatch.h>
#import <sys/unistd.h>
#import <sys/fcntl.h>

@interface MADDirectoryMonitor ()

    @property (nonatomic, assign)   int fileDescriptor;
    @property (nonatomic, copy)     NSURL *URL;
    @property (nonatomic, strong) dispatch_queue_t directoryMonitorQueue;
    @property (nonatomic, strong) dispatch_source_t directoryMonitorSource;

@end

const char * MADQueueFileSystemWatcher = "com.everydayapps.mad.filesystem.watcher";
static const int NotListening = -1;

@implementation MADDirectoryMonitor

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

    if (self.directoryMonitorSource == nil && self.fileDescriptor == NotListening) {
    
        const char *path = [self.URL.path cStringUsingEncoding:NSUTF8StringEncoding];
        self.fileDescriptor = open(path, O_EVTONLY);

        if (self.fileDescriptor < 0) return;
        
        id directoryMonitorQueue = dispatch_queue_create(MADQueueFileSystemWatcher,
                                                         DISPATCH_QUEUE_CONCURRENT);
        self.directoryMonitorQueue = directoryMonitorQueue;
        
        unsigned long mask = DISPATCH_VNODE_DELETE | DISPATCH_VNODE_EXTEND |
        DISPATCH_VNODE_RENAME | DISPATCH_VNODE_ATTRIB;
        
        id directoryMonitorSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
                                                           (uintptr_t)self.fileDescriptor,
                                                           mask, self.directoryMonitorQueue);
        self.directoryMonitorSource = directoryMonitorSource;
        
        MADDirectoryMonitor __weak *weakself = self;

        dispatch_source_set_event_handler(self.directoryMonitorSource, ^{
            MADDirectoryMonitor *sself = weakself;
            [sself.delegate directoryMonitorDidObserveChange:sself];
        });
        
        dispatch_source_set_cancel_handler(self.directoryMonitorSource, ^{
            MADDirectoryMonitor *sself = weakself;
            close(sself.fileDescriptor);
            sself.fileDescriptor = NotListening;
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

@end
