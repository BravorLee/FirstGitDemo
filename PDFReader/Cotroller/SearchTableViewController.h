//
//  SearchTableViewController.h
//  LeePDFViewer
//
//  Created by llbt on 2019/1/10.
//  Copyright © 2019年 llbt. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <PDFKit/PDFKit.h>

@protocol SearchTableViewControllerDelegate;

@interface SearchTableViewController : UITableViewController <UISearchBarDelegate, PDFDocumentDelegate>

@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) PDFDocument *pdfDocument;
@property (strong, nonatomic) NSMutableArray<PDFSelection *> *searchResultArray;

@property (nonatomic, weak) id <SearchTableViewControllerDelegate> delegate;

@end

@protocol SearchTableViewControllerDelegate <NSObject>

-(void)searchTableViewControllerDidSelectPdfSelection:(PDFSelection *)pdfSelection;

@end
