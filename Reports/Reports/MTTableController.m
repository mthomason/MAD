//
//  MTTableController.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTTableController.h"
#import <CoreData/CoreData.h>

#import "MTTableLayout.h"
#import "MTDataFormatter.h"

#import "MTQuery.h"
#import "MTTableCell.h"
#import "MTTableCellHeader.h"

#import "MTDatabase.h"
#import "MTDataTable.h"
#import "MTDatabaseField.h"

#import "NSError+UserInterface.h"
#import "UIColor+EverydayApps.h"

@interface MTTableController ()
    <UICollectionViewDataSource, MTTableLayoutDelegate, MTDatabaseProtocol>

@property (nonatomic, strong) MTQuery *query;
@property (nonatomic, strong) MTDataTable *datatable;
@property (nonatomic, strong, readwrite) MTDataFormatter *tableFormatter;
@property (nonatomic, copy, readwrite) NSArray *fieldKeys;
@property (nonatomic, copy, readwrite) NSArray *fieldSizes;

@end

@implementation MTTableController

- (void)dealloc {
    [_query database].delegate = nil;
}

- (MTDataTable *)dataTableForQuery:(MTQuery *)query {
    return [self datatable];
}

- (instancetype)initWithQuery:(MTQuery *)query {
    
    NSUInteger rowCount = 0;
    NSUInteger columnCount = 0;
    MTTableLayout *tableLayout = [[MTTableLayout alloc] initWithColumnCount:columnCount andRowCount:rowCount];
    
    self = [super initWithCollectionViewLayout:tableLayout];
    if (self) {
        
        [query database].delegate = self;
        MTDataTable *datatable = [MTTableController dataTableWithObjectId:[[query queryObject] objectID]];
        self.datatable = datatable;
        tableLayout.delegate = self;
        MTDataFormatter *tableFormatter = [[MTDataFormatter alloc] initWithQuery:query];
        self.tableFormatter = tableFormatter;
        self.query = query;
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initalize];
    self.collectionView.backgroundColor = [UIColor tintColorBlue];
    self.collectionView.alwaysBounceHorizontal = YES;
    self.collectionView.alwaysBounceVertical = YES;
    
    UINavigationItem *navitagionItem = self.navigationItem;
    UIBarButtonItem *barButtonItemDone = [navitagionItem rightBarButtonItem];
    barButtonItemDone.tintColor = [UIColor tintColorWhite];
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activityIndicator startAnimating];
    activityIndicator.hidden = NO;
    activityIndicator.hidesWhenStopped = NO;

    UIBarButtonItem *barButtonItemActive = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [navitagionItem setRightBarButtonItem: barButtonItemActive animated: NO];
    
    __weak MTTableController *weakSelf = self;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{

        __weak MTTableController *weakSelf2 = weakSelf;
        [[[weakSelf tableFormatter] query] performQuery:^(BOOL success, NSError *error) {
            
            [navitagionItem performSelectorOnMainThread:@selector(setRightBarButtonItem:) withObject:barButtonItemDone waitUntilDone:NO];
            [activityIndicator performSelectorOnMainThread:@selector(stopAnimating) withObject:nil waitUntilDone:NO];
            [error performSelectorOnMainThread:@selector(presentErrorOnViewController:) withObject:self waitUntilDone:NO];
            [weakSelf2 performSelectorOnMainThread:@selector(invalidateLayout) withObject:weakSelf2 waitUntilDone:NO];

        }];

    });
}

+ (MTDataTable *)dataTableWithObjectId:(NSManagedObjectID *)objectID {
    NSUInteger hash = [[[objectID URIRepresentation] absoluteString] hash];
    
    NSNumber *typeKey = @(MTDataTableTypeOfTable);
    NSNumber *type = @(MTDataTableTypeVirtual);
    NSNumber *objectIdKey = @(MTDataTableObjectId);
    NSNumber *objectIdV =  @(hash);
    NSDictionary *parameters = @{
                                 typeKey : type,
                                 objectIdKey : objectIdV};
    return [MTDataTable dataTableFactory:parameters];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.collectionView flashScrollIndicators];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [[self.navigationItem titleView] sizeToFit];
}

#pragma mark - Helpers

- (void)invalidateLayout {
    [[self tableFormatter] format];
    UICollectionView *collectionView = self.collectionView;
    [collectionView reloadData];
    [(MTTableLayout *)[self collectionViewLayout] setColumnCount:self.columnCount
                                                     andRowCount:self.rowCount];
    
    for (NSInteger i=0; i<self.columnCount; i++) {

        __unsafe_unretained Class classCollectionViewCell = [MTTableCell class];
        NSString *reuseId = [self reuseIdForColumn:i];
        [self.collectionView registerClass: classCollectionViewCell
                forCellWithReuseIdentifier: reuseId];
        
        __unsafe_unretained Class classCollectionViewCellHeader = [MTTableCellHeader class];
        NSString *reuseIdHeader = [self reuseIdSupplementForColumn:i];
        [self.collectionView registerClass: classCollectionViewCellHeader
                forSupplementaryViewOfKind: @"MTTableCellHeader"
                       withReuseIdentifier: reuseIdHeader];

    }

}

- (void)initalize {
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
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

- (NSString *)reuseIdForColumn:(NSInteger)column {
    return [NSString stringWithFormat:@"%@%ld", [self reuseId], (long)column];
}

- (NSString *)reuseIdSupplementForColumn:(NSInteger)column {
    return [NSString stringWithFormat:@"%@%ld", [self reuseIdSupplement], (long)column];
}

- (NSString *)reuseIdSupplement {
    static NSString * reuseIdSupplement;
    if (reuseIdSupplement == nil) {
        __unsafe_unretained Class class = [self class];
        reuseIdSupplement = [NSStringFromClass(class) stringByAppendingString:@"Sup"];
    }
    return reuseIdSupplement;
}

- (NSUInteger)rowCount {
    return [[self datatable] numberOfRows];
}

- (NSUInteger)columnCount {
    return [[self datatable] numberOfColumns];

}
#pragma mark - Delegates

#pragma mark - Collection View Datasource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger numberOfItems = [self rowCount] * [self columnCount];
    return numberOfItems;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger column =[(MTTableLayout *)[collectionView collectionViewLayout] columnForIndexPath:indexPath];
    NSUInteger row = [(MTTableLayout *)[self collectionViewLayout] rowForIndexPath:indexPath];
    NSString *reuseId = [self reuseIdForColumn:column];
    
    MTTableCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseId
                                                                  forIndexPath:indexPath];
    
    NSDictionary *rowData = [[self datatable] objectAtRow:row];
    NSString *fieldKey = [[self query] fieldKeyForIndex:column];
    id fieldValue = rowData[fieldKey];
    cell.label.text = [NSString stringWithFormat:@"%@", fieldValue];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    NSUInteger column =[(MTTableLayout *)[collectionView collectionViewLayout] columnForIndexPath:indexPath];
    NSString *reuseId = [self reuseIdSupplementForColumn:column];
    NSString *fieldKey = [[self query] fieldKeyForIndex:indexPath.row];
    NSArray *components = [fieldKey componentsSeparatedByString:@"."];
    NSString *safeFieldName = [components lastObject];
    NSString *fieldName = [safeFieldName stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    
    MTTableCellHeader *view = [collectionView dequeueReusableSupplementaryViewOfKind:@"MTTableCellHeader" withReuseIdentifier:reuseId forIndexPath:indexPath];
    [[view label] setText:fieldName];
    return view;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(CGSizeZero.height + 22.0000f, CGSizeZero.width, CGSizeZero.height, CGSizeZero.width);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout widthRequiredColumn:(NSInteger)section {
    
    NSUInteger column =  section;
    NSString *fieldKey = [[self query] fieldKeyForIndex:column];
    MTDatabaseField *field = [[self query] fields][fieldKey];
    NSInteger maxNumberOfCharacters = [field calculatedWidth];
    if (maxNumberOfCharacters <= 0) {
        maxNumberOfCharacters = 4;
    }
    [UIFont systemFontOfSize:[UIFont systemFontSize]];
    
    UIFontDescriptor *fontDescriptorBody = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
    CGFloat sizeBody = [fontDescriptorBody.fontAttributes[UIFontDescriptorSizeAttribute] floatValue];
    
    UIFont *bodyFont = [UIFont fontWithDescriptor:fontDescriptorBody size:sizeBody];
    
    NSString *s = [@"" stringByPaddingToLength:maxNumberOfCharacters withString:@"X" startingAtIndex:0];
    CGSize size = [s sizeWithAttributes:@{NSFontAttributeName: bodyFont}];
        
    return size.width < 75.0000f ? 75.0000f : (size.width > 280.0000f) ? 280.0000f : size.width;
}

@end
