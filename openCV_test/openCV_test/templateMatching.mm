//
//  templateMatching.m
//  openCV_test
//
//  Created by mark on 14-6-16.
//  Copyright (c) 2014年 mark. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "templateMatching.h"

#include "opencv2/highgui/highgui.hpp"
#include "opencv2/imgproc/imgproc.hpp"
#include <iostream>
#include <stdio.h>

using namespace std;
using namespace cv;

/// 全局变量
static Mat img, templ, result;
static const char* image_window = "Source Image";
static const char* result_window = "Result window";

static int match_method;
static int max_Trackbar = 5;

/// 函数声明
void MatchingMethod( int, void* );

/** @主函数 */
int templateMatchcingMain( int argc, char** argv )
{
    /// 载入原图像和模板块
    img = imread( argv[1], 1 );  //原图
    templ = imread( argv[2], 1 );  //需要查找地点匹配图
    
    /// 创建窗口
    namedWindow( image_window, CV_WINDOW_AUTOSIZE );
    namedWindow( result_window, CV_WINDOW_AUTOSIZE );
    
    /// 创建滑动条
    const char* trackbar_label = "Method: \n 0: SQDIFF \n 1: SQDIFF NORMED \n 2: TM CCORR \n 3: TM CCORR NORMED \n 4: TM COEFF \n 5: TM COEFF NORMED";
    createTrackbar( trackbar_label, image_window, &match_method, max_Trackbar, MatchingMethod );
    
    MatchingMethod( 0, 0 );
    
    waitKey(0);
    return 0;
}

/**
 * @函数 MatchingMethod
 * @简单的滑动条回调函数
 */
void MatchingMethod( int, void* )
{
    /// 将被显示的原图像
    Mat img_display;
    img.copyTo( img_display );
    
    /// 创建输出结果的矩阵
    int result_cols =  img.cols - templ.cols + 1;
    int result_rows = img.rows - templ.rows + 1;
    
    //对比用的图最后的那几行或者几列和原图大小一样的时候不需要再往后移动，所以结果图不需要保留这些阵列
    result.create( result_cols, result_rows, CV_32FC1 );
    
    matchTemplate( img, templ, result, match_method );          //匹配
    normalize( result, result, 0, 1, NORM_MINMAX, -1, Mat() );  //标准化
    
    /// 通过函数 minMaxLoc 定位最匹配的位置
    double minVal; double maxVal;
    cv::Point minLoc; cv::Point maxLoc;
    cv::Point matchLoc;
    
    minMaxLoc( result, &minVal, &maxVal, &minLoc, &maxLoc, Mat() );
    
    /// 对于方法 SQDIFF 和 SQDIFF_NORMED, 越小的数值代表更高的匹配结果. 而对于其他方法, 数值越大匹配越好
    if( match_method  == CV_TM_SQDIFF || match_method == CV_TM_SQDIFF_NORMED )
    { matchLoc = minLoc; }
    else
    { matchLoc = maxLoc; }
    
    /// 让我看看您的最终结果
    //在原图上画一个红色框,  匹配位置+模板图象的大小，两个point锁定一个矩形区域
    rectangle( img_display, matchLoc, cv::Point( matchLoc.x + templ.cols , matchLoc.y + templ.rows ), Scalar::all(0), 2, 8, 0 );
    //在结果图上画一个红色框
    rectangle( result, matchLoc, cv::Point( matchLoc.x + templ.cols , matchLoc.y + templ.rows ), Scalar::all(0), 2, 8, 0 );
    
    imshow( image_window, img_display );
    imshow( result_window, result );
    
    return;
}