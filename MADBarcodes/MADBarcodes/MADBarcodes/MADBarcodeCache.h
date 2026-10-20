//
//  MADBarcodeCache.h
//  MADBarcodes
//
//  Created by Michael Thomason on 10/20/26.
//  Copyright © 2026 Michael Thomason. All rights reserved.
//

#ifndef MADBarcodes_MADBarcodeCache_h
#define MADBarcodes_MADBarcodeCache_h

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

@class MADBarcode;
@class UIImage;

// Rendered barcode images, keyed by MADBarcode's -renderCacheKey.  A report
// draws one barcode per detail row and values repeat, so a hit replaces the
// whole zint encode and raster pass with one image draw.
@interface MADBarcodeCache : NSObject

+ (MADBarcodeCache *)sharedCache;

// The rendered image, rendering and storing it on a miss.  nil when the
// barcode cannot be encoded; the message from that attempt is kept for
// -errorMessageForBarcode:.
- (UIImage *)imageForBarcode:(MADBarcode *)barcode;

// The message from the failed render stored by -imageForBarcode:, or nil.
- (NSString *)errorMessageForBarcode:(MADBarcode *)barcode;

// Drops every rendered image and error message.  The render key already
// covers every draw-affecting input, so this is belt-and-braces; the viewer
// calls it when a refresh completes.
- (void)flush;

@end

#endif
