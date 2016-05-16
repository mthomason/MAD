//
//  MTPrintingProtocol.h
//  Reports
//
//  Created by Michael Thomason on 2/12/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTPrintingProtocol_h
#define Reports_MTPrintingProtocol_h

#import <Foundation/NSObject.h>

@class MTReportViewerPrintPageRenderer;

@protocol MTPrintingProtocol <NSObject>
@required
    - (MTReportViewerPrintPageRenderer *)printPageRender;
@end

#endif
