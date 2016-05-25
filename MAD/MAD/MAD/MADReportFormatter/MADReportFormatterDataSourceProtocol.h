//
//  MADReportFormatterDataSourceProtocol.h
//  MAD
//
//  Created by Michael Thomason on 5/24/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADReportFormatterDataSourceProtocol_h
#define MADReportFormatterDataSourceProtocol_h

@protocol MTReportFormatterDataSource <NSObject>

    - (BOOL)cacheExist;
    - (NSEnumerator *)enumeratorForReportData;
    - (NSDictionary *)copyDataForCacheId:(NSNumber *)cachedID;

@end

#endif /* MADReportFormatterDataSourceProtocol_h */
