//
//  MTActivityItemProviderPdf.h
//  MAD
//
//  Created by Michael Thomason on 2/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTActivityItemProviderPdf_h
#define Reports_MTActivityItemProviderPdf_h

#import <UIKit/UIKit.h>

@protocol MTActivityItemProviderDelegate <NSObject>

- (void)showPrintDialog;

@end

@interface MTActivityItemProviderPdf : UIActivityItemProvider

@property (nonatomic, weak) id <MTActivityItemProviderDelegate> delegate;

@property (nonatomic, weak, readonly) UIActivityViewController *activityViewController;

@end

#endif
