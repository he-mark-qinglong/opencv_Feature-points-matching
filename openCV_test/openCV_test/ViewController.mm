//
//  ViewController.m
//  openCV_test
//
//  Created by mark on 14-5-29.
//  Copyright (c) 2014年 mark. All rights reserved.
//

#import "ViewController.h"
#include "simpleMatching.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#include "CalcHist.h"


@interface ViewController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate,
CvVideoCameraDelegate>
@property (retain,nonatomic)UIPopoverController *imagePicker;

@property (nonatomic, retain) CvVideoCamera* videoCamera;
@property NSNumber *cameraBtnTag;
@end


@implementation ViewController
- (void)viewDidLoad
{
    [super viewDidLoad];

    [[self.cameraBtn rac_signalForControlEvents:UIControlEventTouchUpInside]
     subscribeNext:^(id x) {
        //抓图，暂时还不知道怎么做
         // Do any additional setup after loading the view, typically from a nib.
         self.videoCamera = [[CvVideoCamera alloc] initWithParentView:self.imageA];
         self.videoCamera.delegate = self;
         
         self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
         self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
         self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
         self.videoCamera.defaultFPS = 30;
         self.videoCamera.grayscaleMode = NO;
         
         [self.videoCamera start];
     }];
    
    self.takePictureBtn.tag = 1;  //选取完图片需要用这个值判定为哪一个UIImageView设置图片，用它区分
    self.takePictureBtn2.tag = 2;
    [[self.takePictureBtn rac_signalForControlEvents:UIControlEventTouchUpInside]
     subscribeNext:^(id x) {
         self.cameraBtnTag = @(((UIButton*)x).tag);
         [self gotoCamera];
     }];
    [[self.takePictureBtn2 rac_signalForControlEvents:UIControlEventTouchUpInside]
     subscribeNext:^(id x) {
         
         self.cameraBtnTag = @(((UIButton*)x).tag);
         [self gotoCamera];
     }];
}

- (void)gotoCamera
{
    BOOL isCameraSupport = [UIImagePickerController
                            isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    if (!isCameraSupport) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"温馨提示"
                                                       message:@"你的设备不支持拍照"
                                                      delegate:self
                                             cancelButtonTitle:@"ok"
                                             otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];  //初始化
    picker.delegate      = self;
    picker.allowsEditing = YES;  //设置可编辑
    picker.sourceType    = UIImagePickerControllerSourceTypeCamera;
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    return;
    
    [self matchTest];
    [self calcHistTest];
}

- (void) calcHistTest
{
    UIImage *image = [UIImage imageNamed:@"IMG_0140.png"];
    self.imageA.image = image;
    Mat img = [image convertTo_OpenCVMat];
    int ret = calHistMain(img , self);
}
- (void) matchTest
{
    UIImage *image1 = [UIImage imageNamed:@"IMG_0.png"];
    UIImage *image2 = [UIImage imageNamed:@"IMG_0140.png"];
    self.imageA.image = image1;
    self.imageB.image = image2;
    Mat img1 = [image1 convertTo_OpenCVMat];
    Mat img2 = [image2 convertTo_OpenCVMat];
    
    self.imageC.image = getMatch(img1, img2);
    img1.release();
    img2.release();
}

#pragma mark - UIImagePickerControllerDelegate
//点击cancel调用的方法
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveImage:(UIImage *)tempImage WithName:(NSString *)imageName
{
    NSData* imageData = UIImagePNGRepresentation(tempImage);
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    // Now we get the full path to the file
    NSString* fullPathToFile = [documentsDirectory stringByAppendingPathComponent:imageName];
    [imageData writeToFile:fullPathToFile atomically:NO];
}
//点击相册中的图片或者照相机照完后点击use 后触发的方法
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *takedImage;
    if (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary){  //如果打开相册
        [self.imagePicker dismissPopoverAnimated:YES];  //关掉相册
        takedImage = [info objectForKey:UIImagePickerControllerOriginalImage] ;
    }else{  //照相机
        [picker dismissViewControllerAnimated:YES completion:nil];  //关掉照相机
        takedImage = [info objectForKey:UIImagePickerControllerEditedImage] ;
    }
    
    static UIImage *image1 = nil, *image2 = nil;
    //把选中的图片添加到界面中
    if([self.cameraBtnTag  isEqual: @1]){
        self.imageA.image = takedImage;
        image1 = takedImage;
    }else{
        self.imageB.image = takedImage;
        image2 = takedImage;
    }
    
    if( !image1 || !image2)
        return;
    Mat img1 = [image1 convertTo_OpenCVMat];
    Mat img2 = [image2 convertTo_OpenCVMat];

    //将矩阵图像灰度化
    cvtColor(img1, img1, CV_BGR2GRAY, 1); //尾参：无/0保留通道个数；1单通道；3三通道。
    cvtColor(img2, img2, CV_BGR2GRAY, 1); //尾参：无/0保留通道个数；1单通道；3三通道。
    
    self.imageC.image = getMatch(img1, img2);
}
#pragma mark - CvVideoCameraDelegate
- (void)processImage:(cv::Mat&)image
{
    cv::Mat image_copy = image;
    // Do some OpenCV stuff with the image
    cv::Mat image_converted;
    cvtColor(image, image_converted, CV_BGRA2BGR);
    self.imageB.image = [UIImage UIImageFromCVMat:image_converted];
    
    // invert image
    bitwise_not(image_converted, image_converted);
    cvtColor(image_converted, image_copy, CV_BGR2GRAY);
    self.imageC.image = [UIImage UIImageFromCVMat:image_copy];
}

@end



