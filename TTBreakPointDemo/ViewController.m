//
//  ViewController.m
//  TTBreakPointDemo
//
//  Created by zhang liangwang on 17/3/27.
//  Copyright © 2017年 zhangliangwang. All rights reserved.
//

#import "ViewController.h"
#import "MD5.h"

// http://120.25.226.186:32812/resources/videos/minion_01.mp4

// 文件的URL（下载地址）
#define FileURL @"http://120.25.226.186:32812/resources/videos/minion_01.mp4"
// 文件名（沙盒中的文件名）
#define FileName [MD5 md532BitLower:FileURL]
// 文件存放路径（cache）
#define FileFullPath [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true) lastObject] stringByAppendingPathComponent:FileName]
// 文件已下载的长度
#define FileDownLoadLength [[[NSFileManager defaultManager] attributesOfItemAtPath:FileFullPath error:nil][NSFileSize] integerValue]
// 文件的总长度
#define FileTotalLengthFullPath [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true) lastObject] stringByAppendingPathComponent:@"totalLength.mp4"]


@interface ViewController () <NSURLSessionDataDelegate>

@property (nonatomic,strong) NSURLSession *session; //sesson
@property (nonatomic,strong) NSURLSessionDataTask *task; //下载任务
@property (nonatomic,strong) NSOutputStream *outputStream; //写文件的流对象
@property (nonatomic,assign) NSInteger totalLength; //文件的总大小

@end

@implementation ViewController

//MARK:-懒加载
- (NSURLSession *)session
{
    if (_session == nil) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    }
    return _session;
}

- (NSOutputStream *)outputStream {
    if (_outputStream == nil) {
        _outputStream = [NSOutputStream outputStreamToFileAtPath:FileFullPath append:true];
    }
    return _outputStream;
}

- (NSURLSessionDataTask *)task {
    if (_task == nil) {
        // 判断文件已经下载的大小
        NSInteger totalLength = [[NSDictionary dictionaryWithContentsOfFile:FileTotalLengthFullPath][FileName] integerValue];
        NSLog(@"----%zd---",totalLength);
        if (totalLength && totalLength == FileDownLoadLength) {
            NSLog(@"----Already download----");
            return nil;
        }
        
        NSString *url = @"http://120.25.226.186:32812/resources/videos/minion_01.mp4";
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        // 第一次下载 FileDownLoadLength 为0
        NSString *range = [NSString stringWithFormat:@"bytes=%zd-",FileDownLoadLength];
        [request setValue:range forHTTPHeaderField:@"Range"];
        
        _task = [self.session dataTaskWithRequest:request];
    }
    return _task;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSLog(@"--FileFullPath--%@",FileFullPath);
    
}

//MARK:-开始下载
- (IBAction)start:(UIButton *)sender {
    
    [self.task resume];
}

//MARK:-暂停下载
- (IBAction)pause:(UIButton *)sender {
    
    [self.task suspend];
}

//MARK:-NSURLSessionDataDelegate
/*
 * 接收服务器响应
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    //开启流
    [self.outputStream open];
    
    //文件的总长度(此次请求的是当前请求服务器，服务器返回的最大数据量),故加上之前下载的
    //第一次请求的时候 FileDownLoadLength 长度为0
    self.totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + FileDownLoadLength;
    
    //存储总长度 第一次请求时FileTotalLengthFullPath为空
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:FileTotalLengthFullPath];
    if (dict == nil) dict = [NSMutableDictionary dictionary]; //第一次请求的时FileTotalLengthFullPath为空
    dict[FileName] = @(self.totalLength);
    [dict writeToFile:FileTotalLengthFullPath atomically:true]; //把dict写入内存
    
    //允许接受响应
    completionHandler(NSURLSessionResponseAllow);
    
}

/*
 * 接收服务器数据，可能会被调用多次
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    // 写入数据
    [self.outputStream write:data.bytes maxLength:data.length];
    
    // 当前的下载长度
//    NSInteger downloadLength = [[[NSFileManager defaultManager] attributesOfItemAtPath:FileFullPath error:nil][NSFileSize] integerValue];
    
    //下载进度
    NSLog(@"-----%f",1.0 * FileDownLoadLength / self.totalLength);
}

/*
 * 下载完成（成功或失败）
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    //关闭流
    [self.outputStream close];
    self.outputStream = nil;
    //关闭任务
    self.task = nil;
    
}


@end



















































