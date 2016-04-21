//
//  MADFileManager
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADOpenDocumentManager.h"

NSString * const MADFileManagerOpenUrl      = @"MADFileManagerOpenUrl";
NSString * const MADFileManagerOpenFiles    = @"MADFileManagerOpenFiles";

@interface MADOpenDocumentManager ()

    @property (nonatomic, strong) NSMutableDictionary *openFiles;   //MADocument stored by their NSURLS
    @property (nonatomic, copy, readwrite) NSURL *openUrl;

@end

@implementation MADOpenDocumentManager

- (void)dealloc {
    [self.openFiles removeAllObjects];
}

- (instancetype)init {
    if (self = [super init]) {
        NSMutableDictionary *openFiles = [[NSMutableDictionary alloc] init];
        self.openFiles = openFiles;
        self.openUrl = nil;
    }
    return self;
}

- (void)setOpenDocument:(UIManagedDocument *)document {
    if (document) {
        self.openUrl = document.fileURL.copy;
        NSString *path = self.openUrl.absoluteString;
        self.openFiles[path] = document;
    }
}

- (UIManagedDocument *)openDocument {
    return self.openFiles[self.openUrl.absoluteString];
}

- (void)removeDocumentWithUrl:(NSURL *)url {
    NSString *path = url.absoluteString;
    [self.openFiles removeObjectForKey:path];
    if ([url isEqual:self.openUrl]) {
        self.openUrl = nil;
    }
}

@end
