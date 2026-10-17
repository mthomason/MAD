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
#import <Foundation/NSFileManager.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSDate.h>

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

	// The thumbnail URL is stable for a document, but the file behind it is
	// rewritten by the viewer's page view.  Comparing the path alone skipped
	// that rewrite and left the cell showing its old (often blank) image; the
	// modification date is what tells the two writes apart.
	NSDictionary <NSFileAttributeKey, id> *attributes = nil;
	if (path != nil) {
		attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
	}
	NSDate *modificationDate = attributes[NSFileModificationDate];
	BOOL samePath = (_thumbnailAbsolutePath != nil && [_thumbnailAbsolutePath isEqualToString:path]);
	BOOL sameDate = (modificationDate != nil && [self.lastChangeDate isEqual:modificationDate]);
	if (samePath && sameDate) return;

	_thumbnailAbsolutePath = [path copy];
	self.lastChangeDate = modificationDate;
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
