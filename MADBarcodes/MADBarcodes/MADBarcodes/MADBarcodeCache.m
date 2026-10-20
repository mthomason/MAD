//
//  MADBarcodeCache.m
//  MADBarcodes
//
//  Created by Michael Thomason on 10/20/26.
//  Copyright © 2026 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADBarcodeCache.h"
#import "MADBarcode.h"

#import <UIKit/UIImage.h>

// The rendering primitive behind -[MADBarcode renderedImage] also reports the
// message from the failed zint pass, so a miss costs one encode whether it
// succeeds or not.  It stays off MADBarcode.h; MADBarcode.m declares it too.
@interface MADBarcode (MADBarcodeCacheRendering)
- (UIImage *)renderedImageWithErrorMessage:(NSString * __autoreleasing *)errorMessage;
@end

// NSCache never evicts without a limit, and a report can carry thousands of
// distinct barcode values.  The cost is the uncompressed raster (three bytes
// per pixel), so 64 MB holds several hundred typical labels.
static const NSUInteger MADBarcodeCacheTotalCostLimit = 64 * 1024 * 1024;

@implementation MADBarcodeCache {
	NSCache<NSString *, UIImage *> *_images;
	NSCache<NSString *, NSString *> *_errors;
}

+ (MADBarcodeCache *)sharedCache {
	static MADBarcodeCache *sharedCache = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedCache = [[MADBarcodeCache alloc] init];
	});
	return sharedCache;
}

- (instancetype)init {
	if (self = [super init]) {
		_images = [[NSCache alloc] init];
		_images.totalCostLimit = MADBarcodeCacheTotalCostLimit;
		_errors = [[NSCache alloc] init];
	}
	return self;
}

- (UIImage *)imageForBarcode:(MADBarcode *)barcode {
	NSString *key = barcode.renderCacheKey;
	UIImage *image = [_images objectForKey:key];
	if (image != nil) {
		return image;
	}
	if ([_errors objectForKey:key] != nil) {
		return nil;
	}

	NSString *errorMessage = nil;
	image = [barcode renderedImageWithErrorMessage:&errorMessage];
	if (image != nil) {
		CGImageRef cgImage = image.CGImage;
		NSUInteger cost = (NSUInteger)(CGImageGetBytesPerRow(cgImage) * CGImageGetHeight(cgImage));
		[_images setObject:image forKey:key cost:cost];
	} else if (errorMessage != nil) {
		[_errors setObject:errorMessage forKey:key];
	}
	return image;
}

- (NSString *)errorMessageForBarcode:(MADBarcode *)barcode {
	return [_errors objectForKey:barcode.renderCacheKey];
}

- (void)flush {
	[_images removeAllObjects];
	[_errors removeAllObjects];
}

@end
