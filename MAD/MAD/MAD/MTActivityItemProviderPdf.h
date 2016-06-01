//
//  MADActivityItemProviderPdf.h
//  MAD
//
//  Created by Michael Thomason on 2/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTActivityItemProviderPdf_h
#define Reports_MTActivityItemProviderPdf_h

#import <UIKit/UIActivityItemProvider.h>

@protocol MADActivityItemProviderDelegate;
@class MADocument;

@interface MTActivityItemProviderPdf : UIActivityItemProvider

    @property (nonatomic, weak) id <MADActivityItemProviderDelegate> delegate;
    @property (nonatomic, weak) MADocument *document;
    @property (nonatomic, weak, readonly) UIActivityViewController *activityViewController;

@end

#endif
