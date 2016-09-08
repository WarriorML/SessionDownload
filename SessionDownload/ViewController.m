//
//  ViewController.m
//  SessionDownload
//
//  Created by MengLong Wu on 16/9/8.
//  Copyright © 2016年 MengLong Wu. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<NSURLSessionDelegate,NSURLSessionDataDelegate>
{
    NSURLSessionDataTask    *_task;
    
    NSFileHandle                *_handle;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSLog(@"%@",NSHomeDirectory());
    
}

- (IBAction)uploadImage:(id)sender
{
    UIImage *image = [UIImage imageNamed:@"123.png"];
    
//    把图片转化为二进制数据
    NSData *data = UIImagePNGRepresentation(image);
    
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080/DownloadAndUpload/upload"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
//    [request setValue:[NSString stringWithFormat:@"%ld",data.length] forHTTPHeaderField:@"Content-Length"];
    
//    上传使用post方式
    [request setHTTPMethod:@"POST"];
    
//    获取session实例
    NSURLSession *session = [NSURLSession sharedSession];
//    参数一：请求
//    参数二：上传的二进制数据
//    参数三：完成后调用的block
    NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromData:data completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"上传完成");
    }];
    
    [task resume];
}
- (IBAction)downloadFile:(id)sender
{
//    创建url
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080/DownloadAndUpload/123.png"];
//    创建request
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
//    获取session实例
    NSURLSession *session = [NSURLSession sharedSession];
//    创建下载任务
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        下载默认到了沙盒tmp(临时)文件夹下，而这个文件夹下的内容随时会被删除，所以我们需要在下载完成之后，把文件移动到Documents文件夹下。这里的location是下载文件的临时路径
        
        NSLog(@"%@",location);
        
        NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/123.png"];
//        NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//        移动图片到Documents文件夹下
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:path] error:nil];
    }];
//    开启任务
    [task resume];
}

- (IBAction)downloadBigFile:(id)sender
{
    if (!_task) {
        NSURL *url = [NSURL URLWithString:@"http://localhost:8080/DownloadAndUpload/123.zip"];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        
        NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:[self getPath] error:nil];
        
        unsigned long long size = [attr fileSize];
//        断点续传添加字段
        [request addValue:[NSString stringWithFormat:@"bytes=%qu-",size] forHTTPHeaderField:@"Range"];
//        根据配置创建session，设置代理
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
//        创建任务
        _task = [session dataTaskWithRequest:request];
//        开启任务
        [_task resume];
    }
}
- (NSString *)getPath
{
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/123.zip"];
}
- (IBAction)pauseDownload:(id)sender
{
//    悬挂会话任务
    [_task suspend];
    
    _task = nil;
}
- (void)URLSession:(NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveResponse:(nonnull NSURLResponse *)response completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler
{
//    可以一直响应
    completionHandler(NSURLSessionResponseAllow);
    
//    如果该文件不存在就创建
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self getPath]]) {
        [[NSFileManager defaultManager] createFileAtPath:[self getPath] contents:nil attributes:nil];
    }
//    根据路径创建文件处理器，向该路径写入文件
    _handle = [NSFileHandle fileHandleForWritingAtPath:[self getPath]];
}
- (void)URLSession:(NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveData:(nonnull NSData *)data
{
//    每次接收到数据把处理器编辑位置移到最后
    [_handle seekToEndOfFile];
//    处理器写入数据
    [_handle writeData:data];
}

- (void)URLSession:(NSURLSession *)session task:(nonnull NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
    NSLog(@"下载完成");
}














@end
