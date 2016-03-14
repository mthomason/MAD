//
//  MTReportFormatterDataSource.h
//  MAD
//
//  Created by Michael Thomason on 9/28/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTReportFormatterDataSource_h
#define MAD_MTReportFormatterDataSource_h

@protocol MTReportFormatterDataSource <NSObject>

    - (BOOL)cacheExist;
    - (NSEnumerator *)enumeratorForReportData;
    - (NSDictionary *)dataForCacheId:(NSNumber *)cachedID;

@end

#endif
