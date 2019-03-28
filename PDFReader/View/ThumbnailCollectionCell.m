//
//  ThumbnailCollectionCell.m
//  PDFKit_Sample
//
//  Created by rajubd49 on 12/4/17.
//  Copyright © 2017 rajubd49. All rights reserved.
//

#import "ThumbnailCollectionCell.h"

@implementation ThumbnailCollectionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
}

-(void)setHighlighted:(BOOL)highlighted
{
    if (highlighted) {
        self.thumbnailImageView.layer.borderColor = [UIColor colorWithRed:21/255.0 green:120/255.0 blue:237/255.0 alpha:1.0].CGColor;
        self.thumbnailImageView.layer.borderWidth = 1.5;
    }else{
        self.thumbnailImageView.layer.borderColor = UIColor.clearColor.CGColor;
    }
}

@end
