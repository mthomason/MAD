//
//  MADReportSectionDataSourceProtocol.h
//  MAD Designer
//
//  Created by Michael on 5/28/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADReportSectionDataSourceProtocol_h
#define MADReportSectionDataSourceProtocol_h

@class MADDesignerSectionView, MADDesignerSectionLabel, MADDesignerLayoutDesignView,
        UITapGestureRecognizer;

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
    - (int64_t)designView:(MADDesignerLayoutDesignView *)designView identifierAtIndex:(NSUInteger)index;
  @optional
    - (MADDesignerSectionView *)designView:(MADDesignerLayoutDesignView *)designView
              sectionViewForSectionAtIndex:(NSUInteger)index;
    - (MADDesignerSectionLabel *)designView:(MADDesignerLayoutDesignView *)designView
          sectionLabelViewForSectionAtIndex:(NSUInteger)index;

@end

#endif /* MADReportSectionDataSourceProtocol_h */
