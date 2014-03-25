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
#import "MTTableCell.h"

@interface MTTableController ()
    <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong, readwrite) MTDataFormatter *tableFormatter;
@end

@implementation MTTableController

- (id)initWithQuery:(MTQuery *)query {
    NSUInteger rowCount = 0;
    NSUInteger columnCount = 0;
    MTTableLayout *tableLayout = [[MTTableLayout alloc] initWithColumnCount:columnCount andRowCount:rowCount];
    self = [super initWithCollectionViewLayout:tableLayout];
    if (self) {
        MTDataFormatter *tableFormatter = [[MTDataFormatter alloc] initWithQuery:query];
        [self setTableFormatter:tableFormatter];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initalize];
    [[self collectionView] setBackgroundColor:[UIColor whiteColor]];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
- (void)invalidateLayout {
    [[self tableFormatter] format];
    UICollectionView *collectionView = [self collectionView];
    [collectionView reloadData];
    [(MTTableLayout *)[self collectionViewLayout] setColumnCount:self.columnCount
                                                                  andRowCount:self.rowCount];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[[self tableFormatter] query] performQuery:^(BOOL success, NSError *error, id results) {
        [self performSelectorOnMainThread:@selector(invalidateLayout) withObject:self waitUntilDone:NO];
    }];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Helpers

- (void)initalize {
    [[self collectionView] setDelegate:self];
    [[self collectionView] setDataSource:self];
    __unsafe_unretained Class classCollectionViewCell = [MTTableCell class];
    [[self collectionView] registerClass:classCollectionViewCell forCellWithReuseIdentifier:[self reuseId]];
}

#pragma mark - Methods

- (NSString *)reuseId {
    static NSString * reuseId;
    if (reuseId == nil) {
        __unsafe_unretained Class class = [self class];
        reuseId = NSStringFromClass(class);
    }
    return reuseId;
}

- (NSUInteger)rowCount {
    return [[[self tableFormatter] records] count];
}

- (NSUInteger)columnCount {
    return [[[self tableFormatter] records] count] > 0 ? [[[[self tableFormatter] records] lastObject] count] : 0;
}
#pragma mark - Delegates

#pragma mark - Collection View Datasource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
   // [[[[self controller] collectionView] collectionViewLayout] invalidateLayout];
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger numberOfItems = [self rowCount] * [self columnCount];
    return numberOfItems;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reuseId = [self reuseId];
    MTTableCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseId
                                                                           forIndexPath:indexPath];
    UILabel *lbl = [[UILabel alloc] initWithFrame:[[cell contentView] frame]];
    [lbl setText:@"Hi"];
    [lbl setBackgroundColor:[UIColor whiteColor]];
    [[cell contentView] addSubview:lbl];
    [[[cell contentView] layer] setBorderWidth:1.0000f];
    [[[cell contentView] layer] setBorderColor:[UIColor darkGrayColor].CGColor];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(75.0000f, 22.0000f);
}

@end
