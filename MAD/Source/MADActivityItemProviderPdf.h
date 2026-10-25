//
//  MADActivityItemProviderPdf.h
//  MAD
//
//  Created by Michael Thomason on 2/21/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADActivityItemProviderPdf_h
#define Reports_MADActivityItemProviderPdf_h

#import <UIKit/UIActivityItemProvider.h>

@protocol MADActivityItemProviderDelegate;

@class MADocument;

@interface MADActivityItemProviderPdf : UIActivityItemProvider

@property (nonatomic, weak) id <MADActivityItemProviderDelegate> delegate;
@property (nonatomic, weak) MADocument *document;
@property (nonatomic, weak, readonly) UIActivityViewController *activityViewController;

@end

#endif
