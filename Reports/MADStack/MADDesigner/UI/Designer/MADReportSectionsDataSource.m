//
//  MADReportSectionsDataSource.m
//  MAD Designer
//
//  Created by Michael on 5/28/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADReportSectionsDataSource.h"
#import "MADDesignerLayoutDesignView.h"
#import <CoreData/NSManagedObjectContext.h>
#import <MAD/MADSectionsLayout.h>
#import <MAD/MADSectionLayout.h>
#import "MADDesignerSectionView.h"
#import "MADDesignerSectionLabel.h"

@interface MADReportSectionsDataSource ()

    @property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
    @property (nonatomic, strong) MADSectionsLayout *sectionsLayout;

@end

@implementation MADReportSectionsDataSource {
    BOOL _needsRefresh;
}

- (void)dealloc {
    _managedObjectContext = nil;
    _eventDelegate = nil;
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super init]) {
        _managedObjectContext = managedObjectContext;
        _needsRefresh = YES;
    }
    return self;
}

- (void)setNeedsRefresh {
    _needsRefresh = YES;
}

- (void)refreshData {
    MADSectionsLayout *sectionsLayout = [[MADSectionsLayout alloc] initWithManagedObjectContext: _managedObjectContext
                                                                                  databaseClass: NULL];
    self.sectionsLayout = sectionsLayout;
    _needsRefresh = NO;
}

- (void)refreshDataIfNeeded {
    if (_needsRefresh) [self refreshData];
}

- (NSUInteger)numberOfSectionsInDesignView:(MADDesignerLayoutDesignView *)designView {
    return self.sectionsLayout.count;
}

- (NSUInteger)numberOfRowsInDesignView:(MADDesignerLayoutDesignView *)designView
                           sectionView:(MADDesignerSectionView *)sectionView
                               section:(NSUInteger)section {
    
}
- (NSUInteger)numberOfElementsInDesignView:(MADDesignerLayoutDesignView *)designView
                               sectionView:(MADDesignerSectionView *)sectionView
                                   section:(NSUInteger)section
                                       row:(NSUInteger)row {
    
}

- (double)designView:(MADDesignerLayoutDesignView *)designView heightForSectionAtIndex:(NSUInteger)index {
    MADSectionLayout *layout = [self.sectionsLayout sectionLayoutAtIndex:index];
    return layout.height;
}

- (NSString *)designView:(MADDesignerLayoutDesignView *)designView
  titleForSectionAtIndex:(NSUInteger)index {
    return [[self.sectionsLayout sectionLayoutAtIndex:index] localizedDisplay];
}

- (int64_t)sectionID:(NSUInteger)index {
    return [[self.sectionsLayout sectionLayoutAtIndex:index] identifier];
}

- (NSNumber *)sectionKey:(NSUInteger)index {
    return @([[self.sectionsLayout sectionLayoutAtIndex:index] identifier]);
}

- (NSNumber *)sectionKeyDetail {
    return @(self.sectionsLayout.detail.identifier);
}

- (MADDesignerSectionView *)designView:(MADDesignerLayoutDesignView *)designView
          sectionViewForSectionAtIndex:(NSUInteger)index {
    MADSectionLayout *section = [self.sectionsLayout sectionLayoutAtIndex:index];
    MADDesignerSectionView *sectionView = [MADDesignerSectionView newDesignerSectionView: section.identifier
                                                                    designViewIdentifier: index
                                                                               isVisible: section.isVisible
                                                                                delegate: self.eventDelegate];
    
    
    return sectionView;
}

- (MADDesignerSectionLabel *)designView:(MADDesignerLayoutDesignView *)designView
      sectionLabelViewForSectionAtIndex:(NSUInteger)index {
    MADSectionLayout *section = [self.sectionsLayout sectionLayoutAtIndex:index];
    NSString *localizedDisplay = [section localizedDisplay];
    MADDesignerSectionLabel *sectionViewLabel = [[MADDesignerSectionLabel alloc] initWithText:localizedDisplay];
    return sectionViewLabel;
}

@end
