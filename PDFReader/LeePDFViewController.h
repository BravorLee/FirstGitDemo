//
//  LeePDFViewController.h
//  LeePDFViewer
//
//  Created by llbt on 2019/1/10.
//  Copyright © 2019年 llbt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PDFKit/PDFKit.h>

@interface LeePDFViewController : UIViewController

@property (nonatomic,copy) NSString *pdfURLString;
@property (nonatomic,strong) PDFDocument *pdfDoc;


@end
