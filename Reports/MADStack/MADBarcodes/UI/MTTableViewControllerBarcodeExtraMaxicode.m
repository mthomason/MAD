//
//  MTViewControllerBarcodeExtraMaxicode.m
//  MAD
//
//  Created by Michael Thomason on 11/12/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTTableViewControllerBarcodeExtraMaxicode.h"

#import <CoreData/NSManagedObjectID.h>

#import <MADCocoaExtensions/NSError+Constructors.h>

#import <MAD/MTKeyChain.h>
#import <MAD/MTDataTable+Factory.h>

#import <MAD/MTDatabase.h>
#import <MAD/MTDatabaseConnection.h>

#import <MAD/MTQuery.h>

#import "MTQueryBuilderChooseFieldViewController.h"

#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryField+Extras.h>

#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>

@interface MTTableViewControllerBarcodeExtraMaxicode ()

    @property (nonatomic, strong) MTDataTable *dataTableSampleData;

@end

@implementation MTTableViewControllerBarcodeExtraMaxicode

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSInteger row = [self.delegate initalEncodingMode];
    NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[MTQueryBuilderChooseFieldViewController class]]) {
        [(MTQueryBuilderChooseFieldViewController *)segue.destinationViewController setDelegate:self];
        [segue.destinationViewController setDocument:self.document];
    }
}

#pragma mark - MTQueryBuilderChooseFieldDelegate

- (void)tableViewControllerChooseFieldDidFinish: (MTQueryBuilderChooseFieldViewController *)controller
                                      withField: (RptqQueryField *)field {
    
    [self.navigationController popViewControllerAnimated:YES];
    
    RptqDatabaseSchemaField *schemaField = [field databaseSchemaField];
    MTDataTable *dataTable = [MTTableViewControllerBarcodeExtraMaxicode newDataTableForMangedObject:schemaField.objectID];
    [self setDataTableSampleData:dataTable];
    MTQuery *querySampleDataField = [[MTQuery alloc] initWithQueryType: MTQueryTypeSampleDataField
                                                                object: schemaField];
    NSError * __autoreleasing error = NULL;
    bool success = [querySampleDataField performQueryWithError:&error];
    if (success) {
        MTDataTable * __autoreleasing dt = [querySampleDataField.database.delegate dataTableForQuery:querySampleDataField];
        [self setDataTableSampleData:dt];
        NSArray *allObjects = [self.dataTableSampleData allObjects];
        [self.delegate barcodeMaxicodeDidChooseSampleData:allObjects];
        [self.tableView reloadData];
    } else {
        MTTableViewControllerBarcodeExtraMaxicode * __weak wself = self;
        [NSError presentError: error
             onViewController: wself
                   completion:^(BOOL presentErrorSuccess) {
                       NSString *key = [NSString stringWithString:querySampleDataField.database.databaseConnection.connectionString];
                       [[MTKeyChain sharedObject] deleteKey:key];
                   }];
        
    }
}

+ (MTDataTable *)newDataTableForMangedObject:(NSManagedObjectID *)objectID {
    NSUInteger hash = objectID.URIRepresentation.absoluteString.hash;
    NSNumber *typeKey = @(MTDataTableTypeOfTable);
    NSNumber *type = @(MTDataTableTypeVirtual);
    NSNumber *objectIdKey = @(MTDataTableObjectId);
    NSNumber *objectIdV =  @(hash);
    NSDictionary *options = @{typeKey : type,
                              objectIdKey : objectIdV};
    MTDataTable *dataTable = [MTDataTable newDataTableWithDefinition:options];
    return dataTable;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 1) {
        NSInteger numberOfRows = [tableView numberOfRowsInSection:1];
        for (NSInteger i = 0; i < numberOfRows; i++) {
            UITableViewCell *c = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:1]];
            [c setAccessoryType:UITableViewCellAccessoryNone];
        }
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        [self.delegate barcodeMaxicodeDidSetEncodingMode:[cell tag]];
    }
}

@end
