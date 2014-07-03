//
//  UIImage+OpenCV.h
//  openCV_test
//
//  Created by mark on 14-5-29.
//  Copyright (c) 2014年 mark. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (OpenCV)

+(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;
- (cv::Mat)convertTo_OpenCVMat;
- (cv::Mat)cvMatGray;

@end
