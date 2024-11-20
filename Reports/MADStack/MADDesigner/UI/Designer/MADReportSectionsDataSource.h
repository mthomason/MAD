//
//  MADReportSectionsDataSource.h
//  MAD Designer
//
//  Created by Michael on 5/28/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADReportSectionsDataSource_h
#define MAD_MADReportSectionsDataSource_h

#import <objc/NSObject.h>
#import "MADReportSectionDataSourceProtocol.h"

@class NSManagedObjectContext;

@protocol UICollectionViewDelegate, UICollectionViewDataSource,
            MADDesignerSectionLayoutLiquidDelegate;

@interface MADReportSectionsDataSource : NSObject
    <MADDesignerDesignViewDataSource>

    @property (nonatomic, readwrite, weak) id <MADDesignerSectionLayoutLiquidDelegate,
                                                UICollectionViewDelegate,
                                                UICollectionViewDataSource> eventDelegate;

    - (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    - (void)refreshData;

@end

#endif
