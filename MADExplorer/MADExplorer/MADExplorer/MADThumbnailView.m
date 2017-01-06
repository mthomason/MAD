//
//  MADThumbnailView.m
//  MADExplorer
//
//  Created by Michael Thomason on 6/23/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADThumbnailView.h"
#import <UIKit/UIImage.h>
#import <MADFileManager/MADMetaData.h>

static NSString * const MADImageBlank = @"UIImageDocumentBlank";

@interface MADThumbnailView () {
    dispatch_source_t _source;
    
}
    @property (nonatomic, copy) NSString *thumbnailAbsolutePath;
    @property (nonatomic, copy) NSDate *lastChangeDate;

@end

@implementation MADThumbnailView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}

- (void)setThumbnailToDefault {
    MADThumbnailView * __weak weakself = self;
    dispatch_block_t read_iamge = ^{
        @autoreleasepool {
            MADThumbnailView *sself = weakself;
            if (sself) {
                UIImage *result = [UIImage imageNamed:MADImageBlank];
                MADThumbnailView * __weak wself = sself;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    MADThumbnailView *sself1 = wself;
                    if (sself1) {
                        sself1.image = result;
                    }
                });
            }
        }
    };
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), read_iamge);
}

+ (dispatch_queue_t)queue_file_monitor {
    static dispatch_queue_t _queue_file_monitor = nil;
    if (!_queue_file_monitor) {
        const char queue_label[] = "com.everydayapps.mad.queue.monitor.thumbnail";
        dispatch_queue_attr_t queue_attr;
        queue_attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_BACKGROUND, -1);
        _queue_file_monitor = dispatch_queue_create(queue_label, queue_attr);
    }
    return _queue_file_monitor;
}

- (void)setImageSyncFromPath:(NSString *)path {
    MADThumbnailView * __weak wself = self;
    id thumbnail = [[UIImage alloc] initWithContentsOfFile:path];
    if (!thumbnail) thumbnail = [UIImage imageNamed:MADImageBlank];
    dispatch_block_t setThumbnail = ^{
        MADThumbnailView *sself = wself;
        if (sself) {
            sself.image = thumbnail;
        }
    };
    dispatch_sync(dispatch_get_main_queue(), setThumbnail);
}

- (void)setImageFromPath:(NSString *)path {
    MADThumbnailView * __weak wself = self;
    dispatch_block_t read_iamge = ^{
        @autoreleasepool {
            [wself setImageSyncFromPath:path];
        }
    };
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), read_iamge);
   
}

- (void)setThumbnailPath:(NSString *)path {
    
    if (_thumbnailAbsolutePath == nil || ![_thumbnailAbsolutePath isEqualToString: path]) {

        _thumbnailAbsolutePath = path.copy;

        [self setImageFromPath: _thumbnailAbsolutePath];
        
        /*
        int fdes = open(path.UTF8String, O_RDONLY);
        if (_source) dispatch_source_cancel(_source);
        _source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
                                         (uintptr_t)fdes,
                                         DISPATCH_VNODE_WRITE,
                                         [MADThumbnailView queue_file_monitor]);
        
        MADThumbnailView * __weak wself = self;
        dispatch_source_set_event_handler(_source, ^{
        
            MADThumbnailView *sself = wself;
            NSError * __autoreleasing *error;
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: path
                                                                                        error: error];
            
            //NSLog(@"Reading image at path: %@,\n%@", sself.thumbnailAbsolutePath, attributes);
            if (sself) {
                id thumbnail = [[UIImage alloc] initWithContentsOfFile: sself.thumbnailAbsolutePath];
                if (!thumbnail) thumbnail = [UIImage imageNamed:MADImageBlank];
                MADThumbnailView * __weak wself2 = sself;
                dispatch_block_t setThumbnail = ^{
                    MADThumbnailView *sself2 = wself2;
                    if (sself2) {
                        sself2.image = thumbnail;
                    }
                };
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    dispatch_sync(dispatch_get_main_queue(), setThumbnail);
                });
            }
        });
        
        
        dispatch_source_set_cancel_handler(_source, ^{
            close(fdes);
        });
        dispatch_resume(_source);
        //dispatch_main();
        */
    }
}

- (void)setThumbnailURL:(NSURL *)URL {
    NSString *path = URL.path.copy;
    [self setThumbnailPath: path];
    //if (!path) [self setThumbnailToDefault];
    //else [self setThumbnailPath:path];
    
}

- (void)prepareForReuse {
    /*
    _lastChangeDate = nil;
    MADThumbnailView * __weak weakself = self;
    dispatch_block_t read_iamge = ^{
        @autoreleasepool {
            MADThumbnailView *sself = weakself;
            if (sself) {
                UIImage *result = [UIImage imageNamed:MADImageBlank];
                MADThumbnailView * __weak wself = sself;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    MADThumbnailView *sself1 = wself;
                    if (sself1) {
                        sself1.image = result;
                    }
                });
            }
        }
    };
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), read_iamge);*/
}

@end
