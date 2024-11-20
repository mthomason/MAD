//
//  MADReportSectionDataSourceProtocol.h
//  MAD Designer
//
//  Created by Michael on 5/28/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADReportSectionDataSourceProtocol_h
#define MADReportSectionDataSourceProtocol_h

@class MADDesignerSectionView, MADDesignerSectionLabel, MADDesignerLayoutDesignView,
        UITapGestureRecognizer, NSNumber;

@protocol MADDesignerDesignViewDataSource <NSObject>

    - (NSUInteger)numberOfSectionsInDesignView:(MADDesignerLayoutDesignView *)designView;
    - (NSUInteger)numberOfRowsInDesignView:(MADDesignerLayoutDesignView *)designView
                                sectionView:(MADDesignerSectionView *)sectionView
                                    section:(NSUInteger)section;
    - (NSUInteger)numberOfElementsInDesignView:(MADDesignerLayoutDesignView *)designView
                                   sectionView:(MADDesignerSectionView *)sectionView
                                       section:(NSUInteger)section
                                           row:(NSUInteger)row;


    - (double)designView:(MADDesignerLayoutDesignView *)designView heightForSectionAtIndex:(NSUInteger)index;
    - (NSString *)designView:(MADDesignerLayoutDesignView *)designView titleForSectionAtIndex:(NSUInteger)index;
    - (int64_t)sectionID:(NSUInteger)index;
    - (NSNumber *)sectionKey:(NSUInteger)sectionIndex;
    - (NSNumber *)sectionKeyDetail;

  @optional
    - (MADDesignerSectionView *)designView:(MADDesignerLayoutDesignView *)designView
              sectionViewForSectionAtIndex:(NSUInteger)index;
    - (MADDesignerSectionLabel *)designView:(MADDesignerLayoutDesignView *)designView
          sectionLabelViewForSectionAtIndex:(NSUInteger)index;

@end

#endif /* MADReportSectionDataSourceProtocol_h */
