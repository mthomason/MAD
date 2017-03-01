//
//  MADReportPageViewProtocol.h
//  MAD Designer
//
//  Created by Michael on 2/9/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADReportPageViewProtocol_h
#define MADReportPageViewProtocol_h

@protocol MADReportPageViewProtocol <NSObject>
  @required
    - (NSUInteger)pageNumber;
    - (NSDate * _Nullable)lastCacheDate;
    - (MADPrintPageRenderer * _Nullable)printPageRenderer;
    - (NSURL * _Nonnull)thumbnailURL;
  @optional
    - (NSUInteger)numberOfPages;
@end

#endif /* MADReportPageViewProtocol_h */
