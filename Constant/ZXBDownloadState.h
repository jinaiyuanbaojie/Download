//
//  ZXBDownloadStatus.h
//  JSPatchDemoProject
//
//  Created by 晋爱元 on 2017/2/27.
//  Copyright © 2017年 jinaiyuan. All rights reserved.
//

#ifndef ZXBDownloadState_h
#define ZXBDownloadState_h

typedef NS_ENUM(NSUInteger, ZXBDownloadState) {
    ZXBDownloadStateIdle = 0,
    ZXBDownloadStateWaiting,
    ZXBDownloadStateDownloading,
    ZXBDownloadStatePause,
    ZXBDownloadStateDone,
    ZXBDownloadStateCancel,
    ZXBDownloadStateFailed
};

#endif /* ZXBDownloadStatus_h */
