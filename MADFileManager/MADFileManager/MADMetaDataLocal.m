//
//  MADMetaDataLocal.m
//  MADFileManager
//
//  Created by Michael Thomason on 6/22/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADMetaDataLocal.h"
#import <Foundation/NSURL.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSMetadataAttributes.h>
#import <MobileCoreServices/UTType.h>

@interface MADMetaDataLocal ()

    @property (nonatomic, copy, readwrite) NSURL *origionalURL;
    @property (nonatomic, strong) NSDictionary *attributes;

@end

@implementation MADMetaDataLocal

- (instancetype)initWithURL:(NSURL *)url {
    
    if (self = [super init]) {
        
        NSString *path;
        if ((path = url.path)) {
            NSDictionary *attributes;
            NSError *__autoreleasing * error = nil;
            attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: path
                                                                          error: error];
            _attributes = attributes;
        }
        
        _origionalURL = url.copy;
        
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] alloc] initWithURL: _origionalURL];
    return copy;
}

- (NSURL *)URL {
    return _origionalURL;
}

- (NSError *)ubiquitousItemUploadingError { return nil; }

- (NSError *)ubiquitousItemDownloadingError { return nil; }

- (NSString *)ubiquitousItemDownloadingStatus {
    return NSMetadataUbiquitousItemDownloadingStatusCurrent;
}

- (NSString *)name {
    NSString *displayName, *path;
    if ((path = _origionalURL.path)) {
        displayName = [[NSFileManager defaultManager] displayNameAtPath:path].copy;
    } else {
        displayName = @"";
    }
    return displayName.stringByDeletingPathExtension.copy;
}

- (NSString *)fileSystemName {
    id name = _origionalURL.path.lastPathComponent.copy;
    return  name;
}

- (unsigned long long)fileSystemFileSize {
    NSNumber *fileSize;
    fileSize = _attributes[NSFileSize];
    return fileSize.unsignedLongLongValue;
}

- (NSString *)contentType {
    NSString * __nonnull pathExtension = (_origionalURL.pathExtension) ?
                                         (NSString * __nonnull)_origionalURL.pathExtension :@"";
    __nullable CFStringRef cfkey;
    cfkey = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                  (__bridge CFStringRef)pathExtension,
                                                  NULL);
    id key = CFBridgingRelease(cfkey);
    return key;
}

- (NSString *)ubiquitousItemContainerDisplayName {
    NSString *path = _origionalURL.path.lastPathComponent.copy;
    return path;
}

- (NSData *)fileSystemFileCreationDate {
    id date = [_attributes[NSFileCreationDate] copyWithZone:nil];
    return date;
}

- (NSData *)fileSystemContentChangeDate {
    id date = [_attributes[NSFileModificationDate] copyWithZone:nil];
    return date;
}

- (NSURL *)ubiquitousItemURLInLocalContainer {
    id url = _origionalURL.copy;
    return url;
}

- (BOOL)downloaded { return YES; }
- (BOOL)isDownloaded { return YES; }

- (BOOL)isSyncing { return NO; }
- (BOOL)isUbiquitous { return NO; }
- (BOOL)ubiquitousItemDownloadRequested { return NO; }
- (BOOL)ubiquitousItemIsDownloading { return NO; }
- (BOOL)ubiquitousItemIsUploading { return NO; }
- (BOOL)ubiquitousItemIsUploaded { return NO; }
- (BOOL)ubiquitousItemIsExternalDocument { return NO; }
- (BOOL)isUbiquitousItemDownloadingStatusNotDownloaded { return NO; }
- (BOOL)isUbiquitousItemDownloadingStatusDownloaded { return NO; }
- (BOOL)isUbiquitousItemDownloadingStatusCurrent { return NO; }
- (double)ubiquitousItemPercentUploaded { return 100.0; }
- (double)ubiquitousItemPercentDownloaded { return 100.0; }

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    NSString *classname = NSStringFromClass([self class]);
    id uppercaseClassname = [classname uppercaseString];
    [debug appendFormat:@"--%@--\n", uppercaseClassname];
    return debug;
}

@end
