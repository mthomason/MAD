//
//  MTQueryBuilderAdvancedViewController.h
//  Reports
//
//  Created by Michael Thomason on 2/14/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderVisualizationViewController_h
#define Reports_MTQueryBuilderVisualizationViewController_h

#import <UIKit/UIKit.h>
#import <MADFileManager/MADFileManager.h>
#import <MADCocoaExtensions/MADCocoaExtensions.h>
#import "MADocumentProtocol.h"

@interface MADQueryVisualizationViewController : UIViewController
    <MADocumentProtocol>

- (void)redraw;

+ (NSString *)cacheFileNameForFileName:(NSString *)filename;

@end

#endif
