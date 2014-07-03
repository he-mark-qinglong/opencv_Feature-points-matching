//
//  ViewController+ShowMatImage.m
//  openCV_test
//
//  Created by mark on 14-6-17.
//  Copyright (c) 2014年 mark. All rights reserved.
//

#import "ViewController+ShowMatImage.h"
#import "UIImage+OpenCV.h"

@implementation ViewController (ShowMatImage)

- (void) showImage:(cv::Mat)image
{
    self.imageB.image = [UIImage UIImageFromCVMat:image];
}
- (void) showImage:(cv::Mat)image image2:(cv::Mat)image2
{
    self.imageB.image = [UIImage UIImageFromCVMat:image];
    self.imageC.image = [UIImage UIImageFromCVMat:image2];
}

@end
