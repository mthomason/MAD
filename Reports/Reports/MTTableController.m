//
//  MTTableController.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTTableController.h"
#import "MTTableLayout.h"
#import "MTDataFormatter.h"
#import "MTQuery.h"

@interface MTTableController ()
    <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, retain) MTDataFormatter *tableFormatter;

@end

@implementation MTTableController

- (id)initWithQuery:(MTQuery *)query {
    self = [super init];
    if (self) {
        
        MTDataFormatter *tableFormatter = [[MTDataFormatter alloc] initWithQuery:query];
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];


}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Helpers

- (void)initalize {

    
    
    //MTTableLayout *tableLayout = [[MTTableLayout alloc] initWithColumnCount: andRowCount:];
    //[[self collectionView] setCollectionViewLayout:tableLayout];
    [[self collectionView] setDelegate:self];
    [[self collectionView] setDataSource:self];
}

#pragma mark - Delegates

#pragma mark - Collection View Datasource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
}

@end
