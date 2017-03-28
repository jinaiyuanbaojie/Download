//
//  ZXBResourceDownloader.m
//  JSPatchDemoProject
//
//  Created by 晋爱元 on 2017/3/7.
//  Copyright © 2017年 jinaiyuan. All rights reserved.
//

#import "ZXBResourceDownloader.h"
#import "ZXBDownloadManager.h"
#import "ZXBDownloadFileUtils.h"
#import "ZXBDownloadItem.h"
#import "ZXBDownloadError.h"

#pragma mark - AFNetworking

#ifndef NSFoundationVersionNumber_iOS_8_0
#define ZXB_NSFoundationVersionNumber_With_Fixed_5871104061079552_bug 1140.11
#else
#define ZXB_NSFoundationVersionNumber_With_Fixed_5871104061079552_bug NSFoundationVersionNumber_iOS_8_0
#endif

static dispatch_queue_t zxb_url_session_manager_creation_queue() {
    static dispatch_queue_t zxb_url_session_manager_creation_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        zxb_url_session_manager_creation_queue = dispatch_queue_create("com.iflytek.edu.zxb.session.manager.creation", DISPATCH_QUEUE_SERIAL);
    });
    
    return zxb_url_session_manager_creation_queue;
}

static void zxb_url_session_manager_create_task_safely(dispatch_block_t block) {
    if (NSFoundationVersionNumber < ZXB_NSFoundationVersionNumber_With_Fixed_5871104061079552_bug) {
        dispatch_sync(zxb_url_session_manager_creation_queue(), block);
    } else {
        block();
    }
}

@interface ZXBResourceDownloader()
@property (nonatomic,strong) NSOutputStream             *outputStream;
@property (nonatomic,strong) NSString                   *tmpFilePath;
@property (nonatomic,assign) long long                  receivedDataLength;
@property (nonatomic,assign) long long                  totalDataLength;
@property (nonatomic,assign) double                     lastUpadteProgess;//控制更新频率

@property (nonatomic,strong) NSURLSessionDataTask       *dataTask;
@property (nonatomic,strong) ZXBDownloadItem            *item;
@property (nonatomic,copy)   NSString                   *suggestName;

@property (nonatomic,weak)   id<ZXBDownloadSessionDeleagte> downloadDelegate;
@end

@implementation ZXBResourceDownloader

-(instancetype) initWithDownloadItem:(ZXBDownloadItem*)item downloadDelegate:(id<ZXBDownloadSessionDeleagte>) delegate{
    self = [super init];
    if (self) {
        _item = item;
        _receivedDataLength = 0;
        _downloadDelegate = delegate;
        _lastUpadteProgess = 0;
    }
    
    return self;
}

-(ZXBDownloadItem*) matchDownloadItem{
    return _item;
}

-(void) configNewDelegate:(id<ZXBDownloadSessionDeleagte>) delegate{
    _downloadDelegate = delegate;
}

-(void) removeDelegate{
    _downloadDelegate = nil;
}

- (void)dealloc{
    [_outputStream close];
    _outputStream = nil;
}

#pragma mark - 
-(void) startUnderSession:(NSURLSession*) session{
    NSURL *url = [[NSURL alloc] initWithString:_item.downloadUrl];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // Create download directory
    NSString *path = [ZXBDownloadFileUtils tempFilePathWithItem:_item];
    if(![fm fileExistsAtPath:path]){
        [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    // Test if file already exists (partly downloaded) to set HTTP `bytes` header or not
    NSString *totalTmpPath = [NSString stringWithFormat:@"%@/%@.tmp",path,(_item.fileName ? _item.fileName:_item.itemId)];
    self.tmpFilePath = totalTmpPath;
    
    if (![fm fileExistsAtPath:totalTmpPath]) {
        [fm createFileAtPath:totalTmpPath contents:nil attributes:nil];
    }else {
        long long fileSize = [ZXBDownloadFileUtils getFileSizeAtPath:totalTmpPath];
        NSString *range = [NSString stringWithFormat:@"bytes=%lld-", fileSize];
        [request setValue:range forHTTPHeaderField:@"Range"];
        self.receivedDataLength += fileSize;
    }
    
    __block NSURLSessionDataTask *dataTask = nil;
    zxb_url_session_manager_create_task_safely(^{
        dataTask = [session dataTaskWithRequest:request];
    });
    [dataTask resume];

    _dataTask = dataTask;
}

- (void) cancel{
    if (!_item.itemId) {
        return;
    }
    
    [_dataTask cancel];
}

-(NSNumber*) taskIdentifier{
    return @(_dataTask.taskIdentifier);
}

#pragma mark -
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    //存储空间不足
    if(response.expectedContentLength*2 > [ZXBDownloadFileUtils freeDiskSpace].longLongValue){
        NSError *error = [NSError errorWithDomain:ZXBDownloadErrorDomain code:ZXBDownloadErrorNotEnoughFreeDiskSpace userInfo:@{NSLocalizedDescriptionKey:@"存储空间不足"}];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.downloadDelegate notifyDownloadResultWithError:error item:self.item];
        });
        
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    
    self.suggestName = response.suggestedFilename;
    self.totalDataLength = self.receivedDataLength + response.expectedContentLength;
    
    if (self.outputStream) {
        [self.outputStream close];
        self.outputStream = nil;
    }
    
    self.outputStream = [[NSOutputStream alloc] initToFileAtPath:self.tmpFilePath append:YES];
    [self.outputStream open];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    self.receivedDataLength += data.length;
    
    double currentProgress = (self.totalDataLength==0) ? 0 : 1.0*self.receivedDataLength/self.totalDataLength;
    self.item.downloadProgress = currentProgress;
    
    if (currentProgress - self.lastUpadteProgess > 0.01) {
        self.lastUpadteProgess = currentProgress;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.downloadDelegate notifyDownloadItemProgress:self.item];
        });
    }
    
    [self.outputStream write:data.bytes maxLength:data.length];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
    [self.outputStream close];
    self.outputStream = nil;
    
    //下载成功
    if (!error) {
        self.item.downloadProgress = 1;
        
        NSString *path = [ZXBDownloadFileUtils targetFilePathWithItem:_item];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        if(![fm fileExistsAtPath:path]){
            [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        //文件名需要存入数据库
        _item.fileName = (_item.fileName) ? _item.fileName : self.suggestName;
        NSString *totalTargetPath = [NSString stringWithFormat:@"%@/%@",path,_item.fileName];
        NSError *fileError;
        [fm moveItemAtPath:self.tmpFilePath toPath:totalTargetPath error:&fileError];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.downloadDelegate notifyDownloadResultWithError:error item:self.item];
    });
}

@end
