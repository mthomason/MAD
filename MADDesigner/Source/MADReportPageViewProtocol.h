//
//  MADReportPageViewProtocol.h
//  MAD Designer
//
//  Created by Michael on 2/9/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADReportPageViewProtocol_h
#define MADReportPageViewProtocol_h

#import <MAD/MADPrintPageRenderer.h>

@protocol MADReportPageViewProtocol <NSObject>
  @required
	- (NSUInteger)pageNumber;
	- (NSDate * _Nullable)lastCacheDate;
	- (MADPrintPageRenderer * _Nullable)printPageRenderer;
	- (NSURL * _Nonnull)thumbnailURL;
	- (NSURL * _Nonnull)documentURL;
  @optional
	- (NSUInteger)numberOfPages;
@end

#endif /* MADReportPageViewProtocol_h */
