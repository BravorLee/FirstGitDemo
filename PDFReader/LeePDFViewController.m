//
//  LeePDFViewController.m
//  LeePDFViewer
//
//  Created by llbt on 2019/1/10.
//  Copyright © 2019年 llbt. All rights reserved.
//

#import "LeePDFViewController.h"
#import <PDFKit/PDFKit.h>
#import "ThumbnailCollectionCell.h"
#import "SearchTableViewController.h"

#define kPDFViewMaxScaleFactor 4.0
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_X (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height >= 812.0f)
#define kMainViewWidth (self.view.frame.size.width)
#define kMainViewHeight (self.view.frame.size.height)
#define kMainScreenHeight ([[UIScreen mainScreen] bounds].size.height)
#define kBottomViewHeight (IS_IPHONE_X ? 100: 80)

@interface LeePDFViewController () <UICollectionViewDelegate,UICollectionViewDataSource,SearchTableViewControllerDelegate,UIPrintInteractionControllerDelegate>

@property (nonatomic,strong) PDFView *pdfView;
@property (nonatomic,strong) PDFDocument *pdfDocument;

@property (nonatomic,strong) UIView *topControllView;

@property (nonatomic,strong) UIView *bottomThumbnailView;
@property (nonatomic,strong) UICollectionView *pdfThumbnailCollectionView;
@property (strong, nonatomic) NSIndexPath *selectedIndexPath;
@end

@implementation LeePDFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    //注：did load加载，在使用添加childVC时，view.height还未改变
    //[self createPDFViewWithDisplayMode:kPDFDisplaySinglePageContinuous];
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self createPDFViewWithDisplayMode:kPDFDisplaySinglePageContinuous];
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateThumbnailCollectionForSelectedIndex];
}
#pragma mark - 观察者，page是否变化
-(void)addPageChangeObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(PDFViewPageChangedNotification:) name:PDFViewPageChangedNotification object:self.pdfView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(PDFViewAnnotationHitNotification:) name:PDFViewAnnotationHitNotification object:self.pdfView];
}
-(void)removePageChangeObserer
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PDFViewPageChangedNotification object:self.pdfView];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PDFViewAnnotationHitNotification object:self.pdfView];
}
#pragma mark - 点击，显示控制栏
-(void)addTapActions
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showTopAndBottomControlView)];
    [self.pdfView addGestureRecognizer:tap];
}
-(void)showTopAndBottomControlView
{
    [self.view bringSubviewToFront:self.topControllView];
    [self.view bringSubviewToFront:self.bottomThumbnailView];
    [UIView transitionWithView:self.topControllView
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.topControllView.hidden = !self.topControllView.hidden;
                    }
                    completion:NULL];
    [UIView transitionWithView:self.bottomThumbnailView
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.bottomThumbnailView.hidden = !self.bottomThumbnailView.hidden;
                    }
                    completion:NULL];
}
#pragma mark - PDFViewPageChangedNotification
-(void)PDFViewPageChangedNotification:(NSNotification*)notification{
    [self updateThumbnailCollectionForSelectedIndex];
}
#pragma mark - PDFViewAnnotationHitNotification

-(void)PDFViewAnnotationHitNotification:(NSNotification*)notification {
    PDFAnnotation *annotation = (PDFAnnotation*)notification.userInfo[@"PDFAnnotationHit"];
    NSUInteger pageNumber = [self.pdfDocument indexForPage:annotation.destination.page];
    NSLog(@"Page: %lu", (unsigned long)pageNumber);
}
#pragma mark - 顶部，切换显示模式
-(void)leftBtnClcik:(UIButton *)sender
{
    BOOL isSinglePage = (self.pdfView.displayMode == kPDFDisplaySinglePage) ? YES : NO;
    //移除观察者，并移除view
    [self removePageChangeObserer];
    [self.pdfView removeFromSuperview];
    //重新添加新的view
    [sender setImage:isSinglePage ? [UIImage imageNamed:@"pagedouble"] : [UIImage imageNamed:@"pagesingle"] forState:UIControlStateNormal];
    [self createPDFViewWithDisplayMode:isSinglePage ? kPDFDisplaySinglePageContinuous : kPDFDisplaySinglePage ];
    self.topControllView.hidden = YES;
    self.bottomThumbnailView.hidden = YES;
    [self.pdfView goToPage:[self.pdfDocument pageAtIndex:self.pdfView.currentPage.label.intValue]];
}
#pragma mark - 顶部，打印
-(void)leftBtn1Clcik:(UIButton *)sender
{
    UIPrintInteractionController *printVC = [UIPrintInteractionController sharedPrintController];
    printVC.delegate = self;
    //配置打印信息
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.orientation = UIPrintInfoOutputGeneral;
    printInfo.jobName = @"合同文本";
    printVC.printInfo = printInfo;
    //配置打印内容
    printVC.printingItem = [self.pdfDocument dataRepresentation];
    // 设置打印回调block
    void (^completionHandler)(UIPrintInteractionController *,BOOL,NSError *) = ^ (UIPrintInteractionController *printViewCtrl,BOOL completed,NSError *error){
        if (!completed) {
            //未完成
            
        }
        if (completed && error) {
            //完成了，但是出错
            NSLog(@"error = %@",error);
        }
    };
    //弹出打印的VC
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        //pad使用这个方法
        [printVC presentFromRect:self.view.frame inView:self.view animated:YES completionHandler:completionHandler];
    }else{
        //
        [printVC presentAnimated:YES completionHandler:completionHandler];
    }
}

#pragma mark - 顶部，搜索功能
-(void)rightBtnClick:(UIButton *)sender
{
    SearchTableViewController *tableVC = [[SearchTableViewController alloc]init];
    tableVC.pdfDocument = self.pdfDocument;
    tableVC.delegate = self;
    UINavigationController *navigaionController = [[UINavigationController alloc] initWithRootViewController:tableVC];
    [self presentViewController:navigaionController animated:YES completion:^{
        self.topControllView.hidden = YES;
        self.bottomThumbnailView.hidden = YES;
    }];
}
//选中后的代理方法，跳转至相关的地方
-(void)searchTableViewControllerDidSelectPdfSelection:(PDFSelection *)pdfSelection
{
    pdfSelection.color = [UIColor yellowColor];
    self.pdfView.currentSelection  = pdfSelection;
    [self.pdfView goToSelection:pdfSelection];
}
#pragma mark - 顶部，返回
-(void)rightBtn11Click:(UIButton *)sender
{
    NSString *classStr1 =  NSStringFromClass([self.presentedViewController class]);
    NSString *classStr2 =  NSStringFromClass([self.presentingViewController class]);
    NSLog(@"ed = %@, ing = %@",classStr1,classStr2);
    if (self.presentingViewController && kMainViewHeight == kMainScreenHeight) {
        //
        [self dismissViewControllerAnimated:YES completion:nil];
    }else{
        //
        LeePDFViewController *pdfView = [[LeePDFViewController alloc]init];
        //pdfView.pdfURLString = self.pdfURLString;
        pdfView.pdfDoc = self.pdfDocument;
        [self presentViewController:pdfView animated:YES completion:nil];
    }
    
}

#pragma  mark -  刷新底部collectionView
- (void)updateThumbnailCollectionForSelectedIndex {
    NSUInteger row = [self.pdfDocument indexForPage:self.pdfView.currentPage];
    if(self.selectedIndexPath){
        [self.pdfThumbnailCollectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:self.selectedIndexPath]];
    }
    self.selectedIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
    [self.pdfThumbnailCollectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:self.selectedIndexPath]];
    if (![self.pdfThumbnailCollectionView.indexPathsForVisibleItems containsObject:self.selectedIndexPath]) {
        [self.pdfThumbnailCollectionView scrollToItemAtIndexPath:self.selectedIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
}
#pragma mark - collection代理
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.pdfDocument.pageCount > 0 ? self.pdfDocument.pageCount : 0;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ThumbnailCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ThumbnailCollectionCell" forIndexPath:indexPath];
    PDFPage *pdfPage = [self.pdfDocument pageAtIndex:indexPath.item];
    if (pdfPage != nil ) {
        //cell.bounds.size 之前拿的是图片原图尺寸
        UIImage *thumbnail = [pdfPage thumbnailOfSize:CGSizeMake(52, 76) forBox:kPDFDisplayBoxCropBox];
        cell.thumbnailImageView.image = thumbnail;
        cell.pageNumberLabel.text = [NSString stringWithFormat:@"%ld", indexPath.item +1];
    }
    if ([self.pdfView.currentPage isEqual:pdfPage]) {
        cell.highlighted = YES;
    }else{
        cell.highlighted = NO;
    }
    return cell;
}
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PDFPage *pdfPage = [self.pdfDocument pageAtIndex:indexPath.item];
    [self.pdfView goToPage:pdfPage];
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(52, 76);
}
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    // 上 左 下 右
    return UIEdgeInsetsMake(0, 10 , 0, 10);
}
#pragma mark - 懒加载
-(void)createPDFViewWithDisplayMode:(PDFDisplayMode)displayMode
{
    if (![self.view viewWithTag:2831]) {
        CGFloat viewY = kMainViewHeight == kMainScreenHeight ? (IS_IPHONE_X ? 44: 20) : 0;
        self.pdfView = [[PDFView alloc]initWithFrame:CGRectMake(0, viewY, kMainViewWidth, kMainViewHeight)];
        self.pdfView.document = self.pdfDocument;
        self.pdfView.displayMode = displayMode;
        self.pdfView.displayDirection = kPDFDisplayDirectionVertical;
        self.pdfView.scaleFactor = self.pdfView.scaleFactorForSizeToFit;//当前的缩放比例
        self.pdfView.minScaleFactor = self.pdfView.scaleFactorForSizeToFit;//最小缩放比例
        self.pdfView.maxScaleFactor = kPDFViewMaxScaleFactor;//最大缩放比例
        self.pdfView.tag = 2831;
        [self.pdfView usePageViewController:(_pdfView.displayMode == kPDFDisplaySinglePage) ? YES :NO withViewOptions:nil];//使用分页
        [self addTapActions];
        [self addPageChangeObserver];
        [self.view addSubview:self.pdfView];
    }
}
//PDF文件对象
-(PDFDocument *)pdfDocument
{
    if (!_pdfDocument) {
        NSURL *url = [NSURL URLWithString:self.pdfURLString];
        if (!url) {
            _pdfDocument = self.pdfDoc;
        }else{
            _pdfDocument = [[PDFDocument alloc]initWithURL:url];
        }
    }
    return _pdfDocument;
}
//顶部控制器
-(UIView *)topControllView
{
    if (!_topControllView) {
        //1，是否全屏，否为0  是-2，是否有导航栏，否20  是-3，是否为ipx 是88 否64
        CGFloat viewY = (kMainViewHeight == kMainScreenHeight) ? (self.navigationController == nil ? (IS_IPHONE_X ? 44: 20) : (IS_IPHONE_X ? 88: 64)) : 0 ;
        _topControllView = [[UIView alloc]initWithFrame:CGRectMake(0, viewY, kMainViewWidth, 45)];
        //
        UILabel *pdfNameLab = [[UILabel alloc]initWithFrame:_topControllView.bounds];
        pdfNameLab.textAlignment = NSTextAlignmentCenter;
        pdfNameLab.font = [UIFont systemFontOfSize:14.0];
        pdfNameLab.textColor = [UIColor whiteColor];
        //pdfNameLab.text = [self.pdfDocument.outlineRoot childAtIndex:0].label;
        [_topControllView addSubview:pdfNameLab];
        //
        UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        leftBtn.frame = CGRectMake(10, 2, 40, 40);
        [leftBtn addTarget:self action:@selector(leftBtnClcik:) forControlEvents:UIControlEventTouchUpInside];
        [leftBtn setImage:[UIImage imageNamed:@"pagedouble"] forState:UIControlStateNormal];
        [_topControllView addSubview:leftBtn];
        //
        UIButton *leftBtn1 = [UIButton buttonWithType:UIButtonTypeCustom];
        leftBtn1.frame = CGRectMake(50, 2, 40, 40);
        [leftBtn1 addTarget:self action:@selector(leftBtn1Clcik:) forControlEvents:UIControlEventTouchUpInside];
        [leftBtn1 setImage:[UIImage imageNamed:@"leePrint"] forState:UIControlStateNormal];
        [_topControllView addSubview:leftBtn1];
        //
        UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        rightBtn.frame = CGRectMake(kMainViewWidth - 90, 2, 40, 40);
        [rightBtn addTarget:self action:@selector(rightBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [rightBtn setImage:[UIImage imageNamed:@"leeSearch"] forState:UIControlStateNormal];
        [_topControllView addSubview:rightBtn];
        //
        UIButton *rightBtn1 = [UIButton buttonWithType:UIButtonTypeCustom];
        rightBtn1.frame = CGRectMake(kMainViewWidth - 50, 2, 40, 40);
        [rightBtn1 addTarget:self action:@selector(rightBtn11Click:) forControlEvents:UIControlEventTouchUpInside];
        [_topControllView addSubview:rightBtn1];
        if (kMainViewHeight == kMainScreenHeight) {
            [rightBtn1 setImage:[UIImage imageNamed:@"leeClose"] forState:UIControlStateNormal];
        }else{
            [rightBtn1 setImage:[UIImage imageNamed:@"leeOpen"] forState:UIControlStateNormal];
        }
        _topControllView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.7];
        _topControllView.hidden = YES;
        [self.view addSubview:_topControllView];
    }
    return _topControllView;
}
//底部滑动缩略图
-(UIView *)bottomThumbnailView
{
    if (!_bottomThumbnailView) {
        _bottomThumbnailView = [[UIView alloc]initWithFrame:CGRectMake(0, kMainViewHeight - kBottomViewHeight, kMainViewWidth, kBottomViewHeight)];
        _bottomThumbnailView.hidden = YES;
        [_bottomThumbnailView addSubview:self.pdfThumbnailCollectionView];
        [self.view addSubview:_bottomThumbnailView];
    }
    return _bottomThumbnailView;
}
-(UICollectionView *)pdfThumbnailCollectionView
{
    if (!_pdfThumbnailCollectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _pdfThumbnailCollectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 0, kMainViewWidth, kBottomViewHeight) collectionViewLayout:layout];
        _pdfThumbnailCollectionView.dataSource = self;
        _pdfThumbnailCollectionView.delegate = self;
        _pdfThumbnailCollectionView.showsHorizontalScrollIndicator = NO;
        _pdfThumbnailCollectionView.alwaysBounceHorizontal = YES;
        _pdfThumbnailCollectionView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.7];
        [_pdfThumbnailCollectionView registerNib:[UINib nibWithNibName:@"ThumbnailCollectionCell" bundle:nil] forCellWithReuseIdentifier:@"ThumbnailCollectionCell"];
    }
    return _pdfThumbnailCollectionView;
}
@end
