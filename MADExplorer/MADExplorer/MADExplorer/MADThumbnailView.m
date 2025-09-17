//
//  MADThumbnailView.m
//  MADExplorer
//
//  Created by Michael Thomason on 6/23/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADThumbnailView.h"
#import <UIKit/UIImage.h>
#import <MADFileManager/MADMetaData.h>

static NSString * const MADImageBlank = @"UIImageDocumentBlank";

@interface MADThumbnailView ()
@property (nonatomic, copy) NSString *thumbnailAbsolutePath;
@property (nonatomic, copy) NSDate *lastChangeDate;
@end

@implementation MADThumbnailView {
	dispatch_source_t _source;
}

+ (dispatch_queue_t)queue_file_monitor {
	static dispatch_queue_t _queue_file_monitor = nil;
	if (!_queue_file_monitor) {
		_queue_file_monitor = dispatch_queue_create("com.everydayapps.mad.queue.monitor.thumbnail", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_BACKGROUND, -1));
	}
	return _queue_file_monitor;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		self.contentMode = UIViewContentModeScaleAspectFit;
	}
	return self;
}

- (void)setThumbnailToDefault {
	MADThumbnailView * __weak weakself = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		MADThumbnailView *sself = weakself;
		if (sself) {
			UIImage *result = [UIImage imageNamed:MADImageBlank];
			MADThumbnailView * __weak wself = sself;
			dispatch_sync(dispatch_get_main_queue(), ^{
				MADThumbnailView *sself1 = wself;
				if (sself1) {
					sself1.image = result;
					[sself1 setNeedsDisplay];
				}
			});
		}
	});
}

- (void)setImageSyncFromPath:(NSString *)path { }

- (void)setThumbnailPath:(NSString *)path {
	
	if (_thumbnailAbsolutePath == nil || ![_thumbnailAbsolutePath isEqualToString: path]) {

		_thumbnailAbsolutePath = [path copy];
		NSString *thumbnailPath = [path copy];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			
			UIImage *thumbnail = [[UIImage alloc] initWithContentsOfFile:thumbnailPath];
			if (!thumbnail) {
				thumbnail = [UIImage imageNamed:MADImageBlank];
			}
			dispatch_sync(dispatch_get_main_queue(), ^{
				self.image = thumbnail;
				[self setNeedsDisplay];
			});
		});
	}
}

- (void)setThumbnailURL:(NSURL *)URL {
	NSString *path = URL.path;
	if (!path) [self setThumbnailToDefault];
	else [self setThumbnailPath:path];
}

- (void)prepareForReuse {
	self.image = nil;
	self.thumbnailAbsolutePath = nil;
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
