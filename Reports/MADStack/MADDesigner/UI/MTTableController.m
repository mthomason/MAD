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
#import <CoreData/NSManagedObjectID.h>
#import <MAD/MTDataTable+Factory.h>
#import <MADCocoaExtensions/NSError+Constructors.h>
#import <MAD/MTDatabaseConnection.h>

#import "MADTableLayout.h"
#import "MTTableCell.h"
#import "MTTableCellHeader.h"
#import <MAD/RptqQuery.h>
#import <MADFoundation/MTDataTable.h>
#import <MAD/MTDatabase.h>
#import <MAD/MTDatabaseField.h>
#import <MAD/MTQuery.h>
#import <MAD/MADDataFormatter.h>
#import <MAD/MTKeyChain.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import "MADOperationQueue.h"
#import "MADGetCredentialsOperation.h"

@interface MADTableController ()
    <UICollectionViewDataSource, MADTableLayoutDelegate, MTDatabaseProtocol, MADOperationObserver> {
    bool _firstTimeViewDidAppear;
}

    @property (nonatomic, strong) MTQuery *query;
    @property (nonatomic, strong) MTDataTable *datatable;
    @property (nonatomic, strong, readwrite) MADDataFormatter *tableFormatter;
    @property (nonatomic, copy, readwrite) NSArray *fieldKeys;
    @property (nonatomic, copy, readwrite) NSArray *fieldSizes;

    @property (nonatomic, strong) MADOperationQueue *credentialQueue;

@end

@implementation MADTableController

- (void)dealloc {
    [_query database].delegate = nil;
}

- (MTDataTable *)dataTableForQuery:(MTQuery *)query {
    return [self datatable];
}

- (instancetype)initWithQuery:(MTQuery *)query {
    
    NSUInteger rowCount = 0;
    NSUInteger columnCount = 0;
    MADTableLayout *tableLayout = [[MADTableLayout alloc] initWithColumnCount:columnCount andRowCount:rowCount];
    
    if (self = [super initWithCollectionViewLayout:tableLayout]) {
        _firstTimeViewDidAppear = true;
        [query database].delegate = self;
        MTDataTable *datatable = [MADTableController dataTableWithObjectId: ((RptqQuery *)query.queryObject).objectID];
        self.datatable = datatable;
        tableLayout.delegate = self;
        MADDataFormatter *tableFormatter = [[MADDataFormatter alloc] initWithQuery:query];
        self.tableFormatter = tableFormatter;
        self.query = query;
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initalize];
    self.collectionView.backgroundColor = [MADColorEverydayApps newColorBlue];
    self.collectionView.alwaysBounceHorizontal = YES;
    self.collectionView.alwaysBounceVertical = YES;
    
    self.navigationItem.rightBarButtonItem.tintColor = [MADColorEverydayApps newColorWhite];
    
    self.toolbarItems = nil;
    self.navigationController.toolbarHidden = YES;
}

+ (MTDataTable *)dataTableWithObjectId:(NSManagedObjectID *)objectID {
    NSNumber *typeKey = @(MTDataTableTypeOfTable);
    NSNumber *type = @(MTDataTableTypeVirtual);
    NSNumber *objectIdKey = @(MTDataTableObjectId);
    NSNumber *objectIdV =  @(objectID.URIRepresentation.absoluteString.hash);
    NSDictionary *parameters = @{typeKey : type, objectIdKey : objectIdV};
    return [MTDataTable newDataTableWithDefinition:parameters];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activityIndicator startAnimating];
    activityIndicator.hidden = NO;
    activityIndicator.hidesWhenStopped = YES;
    
    UIBarButtonItem *barButtonItemActive = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [self.navigationItem setRightBarButtonItem: barButtonItemActive animated: NO];
    
    MADTableController * __weak weakSelf = self;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        MADTableController *strongself = weakSelf;
        MADTableController * __weak weakSelf2 = strongself;
        NSError * __autoreleasing error = NULL;
        
        /*    NSError * __autoreleasing qerror = NULL;
         bool success = [self.database executeQuery:self withError:&qerror];
         if (!success && error == NULL) {
         *error = qerror;
         }
         return success;
*/
        
        bool success = [strongself.tableFormatter.query performQueryWithError:&error];
        
        MADTableController *strongself2 = weakSelf2;
        
        [strongself2.navigationItem performSelectorOnMainThread: @selector(setRightBarButtonItem:) withObject: strongself2.navigationItem.rightBarButtonItem
                                                  waitUntilDone: NO];
        
        [activityIndicator performSelectorOnMainThread:@selector(stopAnimating) withObject:nil waitUntilDone:NO];
        
        if (!success && error) {
            
            if ([NSThread isMainThread]) {

                __strong MADTableController *weakself4 = strongself2;
                
                [NSError presentError: error onViewController: strongself2 completion:^(BOOL displayErrorSuccess) {
                    NSString *key = [NSString stringWithString:weakself4.query.database.databaseConnection.connectionString];
                    [[MTKeyChain sharedObject] deleteKey:key];
                }];
                
            } else {
                
                NSError *serror = error;
                MADTableController * __weak weakself4 = strongself2;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    
                    MADTableController *strongself3 = weakself4;
                    MADTableController * __weak weakself5 = strongself3;
                    
                    [NSError presentError: serror onViewController: strongself3 completion:^(BOOL displayErrorSuccess) {
                        NSString *key = [NSString stringWithString:weakself5.query.database.databaseConnection.connectionString];
                        [[MTKeyChain sharedObject] deleteKey:key];
                    }];
                    
                });
                
            }
            
        }
        [strongself2 performSelectorOnMainThread:@selector(invalidateLayout) withObject:strongself2 waitUntilDone:NO];
        
        
    });
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.collectionView flashScrollIndicators];
    if (_firstTimeViewDidAppear) {
        _firstTimeViewDidAppear = false;
        [self.collectionView scrollRectToVisible: CGRectMake(CGPointZero.x, CGPointZero.y, self.collectionView.frame.size.width, 1.0000f)
                                        animated: NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    UIViewController *parentViewController = self.navigationController.parentViewController;
    self.navigationController.navigationBar.frame = CGRectMake(self.navigationController.navigationBar.frame.origin.x,
                                                               (parentViewController.navigationController.navigationBar.frame.origin.y +
                                                                parentViewController.navigationController.navigationBar.frame.size.height),
                                                               self.navigationController.navigationBar.frame.size.width,
                                                               self.navigationController.navigationBar.frame.size.height);
    
    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width,
                                                                 self.navigationController.bottomLayoutGuide.length, CGSizeZero.width);
    
    self.collectionView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width,
                                                        self.navigationController.bottomLayoutGuide.length, CGSizeZero.width);
    [self.navigationItem.titleView setNeedsLayout];
}

- (void)viewDidLayoutSubviews {
    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width,
                                                                 self.navigationController.bottomLayoutGuide.length, CGSizeZero.width);
    
    self.collectionView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width,
                                                        self.navigationController.bottomLayoutGuide.length, CGSizeZero.width);
    [super viewDidLayoutSubviews];
}


#pragma mark - Helpers

- (void)invalidateLayout {
    UICollectionView *collectionView = self.collectionView;
    [collectionView reloadData];
    [(MADTableLayout *)[self collectionViewLayout] setColumnCount:self.columnCount
                                                     andRowCount:self.rowCount];
    
    for (NSUInteger i=0; i<self.columnCount; i++) {

        __unsafe_unretained Class classCollectionViewCell = [MTTableCell class];
        NSString *reuseId = [self reuseIdForColumn:(NSInteger)i];
        [self.collectionView registerClass: classCollectionViewCell
                forCellWithReuseIdentifier: reuseId];
        
        __unsafe_unretained Class classCollectionViewCellHeader = [MTTableCellHeader class];
        NSString *reuseIdHeader = [self reuseIdSupplementForColumn:(NSInteger)i];
        [self.collectionView registerClass: classCollectionViewCellHeader forSupplementaryViewOfKind: @"MTTableCellHeader" withReuseIdentifier: reuseIdHeader];

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

#pragma mark MTDatabaseProtocol
- (MADCredential *)getCredentialsForKey:(NSString *)key {
    
}

#pragma mark Collection View Datasource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return (NSInteger)([self rowCount] * [self columnCount]);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger column =[(MADTableLayout *)[collectionView collectionViewLayout] columnForIndexPath:indexPath];
    NSUInteger row = [(MADTableLayout *)[self collectionViewLayout] rowForIndexPath:indexPath];
    NSString *reuseId = [self reuseIdForColumn:(NSInteger)column];
    
    MTTableCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseId forIndexPath:indexPath];
    
    NSDictionary *rowData = [self.datatable objectAtRow:row];
    NSString *fieldKey = [self.query fieldKeyForIndex:column];

    id fieldValue = rowData[fieldKey];
    NSString *text = [[NSString alloc] initWithFormat:@"%@", fieldValue];
    cell.label.text = text;

    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger column =[(MADTableLayout *)collectionView.collectionViewLayout columnForIndexPath:indexPath];
    NSString *reuseId = [self reuseIdSupplementForColumn:(NSInteger)column];
    NSString *fieldKey = [self.query fieldKeyForIndex:(NSUInteger)indexPath.row];
    NSArray <NSString *>  *components = [fieldKey componentsSeparatedByString:@"."];
    NSString *fieldName = [components.lastObject stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    
    MTTableCellHeader *view = [collectionView dequeueReusableSupplementaryViewOfKind:@"MTTableCellHeader" withReuseIdentifier:reuseId forIndexPath:indexPath];
    view.label.text = fieldName;
    return view;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(CGSizeZero.height + 22.0000f, CGSizeZero.width, CGSizeZero.height, CGSizeZero.width);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout widthRequiredColumn:(NSInteger)section {
    
    NSUInteger column = (NSUInteger)section;
    NSString *fieldKey = [self.query fieldKeyForIndex:column];
    MTDatabaseField *field = self.query.fields[fieldKey];
    NSUInteger maxNumberOfCharacters = [field calculatedWidth];
    if (maxNumberOfCharacters <= 0) {
        maxNumberOfCharacters = 4;
    }

    UIFontDescriptor *fontDescriptorBody = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
    CGFloat sizeBody = [fontDescriptorBody.fontAttributes[UIFontDescriptorSizeAttribute] floatValue];
    UIFont *bodyFont = [UIFont fontWithDescriptor:fontDescriptorBody size:sizeBody];
    
    NSString *s = [@"" stringByPaddingToLength:maxNumberOfCharacters withString:@"X" startingAtIndex:0];
    NSDictionary *attributes = @{NSFontAttributeName: bodyFont};
    CGSize size = [s sizeWithAttributes:attributes];
    return size.width < 75.0000f ? 75.0000f : (size.width > 280.0000f) ? 280.0000f : size.width;
}

#pragma mark - MADOperationObserver

- (void)operationDidStart:(MADOperation *)operation { }

- (void)operation:(MADOperation *)operation didProduceOperation:(NSOperation *)newOperation { }

- (void)operationDidFinish:(MADOperation *)operation errors:(NSArray *)errors {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        //[self removeObserverFromObjectForProgress:operation];
        //[self.delegate viewControllerDidFinish: self];
        //self.navigationItem.prompt = NSLocalizedString(MADConnectionViewControllerDefaultPrompt, MADConnectionViewControllerDefaultPrompt);
        //[self enableTextFields];
    }];
}

- (MADCredential *)getCredentialsForDatabaseConnection:(MTDatabaseConnection *)databaseConnection {
    
    // Operation: Get credentials.
    // ---------------------------------------------------
    MADGetCredentialsOperation *getCredentialsOperation = [[MADGetCredentialsOperation alloc] initWithDatabaseConnection: databaseConnection
                                                                                                          viewController: self];
    [getCredentialsOperation addObserver:self];
    
    [self.credentialQueue addOperation: getCredentialsOperation];
    
    //self.getCredentialsOperation = getCredentialsOperation;
    //return nil;
}

@end
