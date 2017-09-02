//
//  MADReportFormatterDataSourceProtocol.h
//  MAD
//
//  Created by Michael Thomason on 5/24/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADReportFormatterDataSourceProtocol_h
#define MADReportFormatterDataSourceProtocol_h

@protocol MADReportFormatterDataSource <NSObject>

    - (BOOL)cacheExist;
    - (NSEnumerator <NSDictionary *> *)enumeratorForReportData;
    - (NSDictionary *)dataForRow:(NSUInteger)cachedID;

@end

#endif /* MADReportFormatterDataSourceProtocol_h */
