//
//  MADDocumentPageController.h
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADDocumentPageController_h
#define Reports_MADDocumentPageController_h

#import <UIKit/UIViewController.h>

@protocol MADPrintingProtocol;

@class MADocument, MADPageViewAttributes, MADDocumentScroller;

@interface MADDocumentPageController : UIViewController

@property (nonatomic, weak) id <MADPrintingProtocol> delegate;
@property (readonly, nonatomic, weak) MADDocumentScroller *documentScroller;
@property (readonly, nonatomic, weak) UIView *documentView;
@property (readonly, nonatomic, copy) MADPageViewAttributes *pageViewAttributes;

+ (instancetype)newDocumentPageController:(MADocument *)doc pageAttributes:(MADPageViewAttributes *)abbribs;
- (instancetype)initWithDocument:(MADocument *)doc andPageAttributtes:(MADPageViewAttributes *)abbribs;

@end

#endif
