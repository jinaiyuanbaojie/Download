//
//  ZXBDownloadError.h
//  JSPatchDemoProject
//
//  Created by 晋爱元 on 2017/3/8.
//  Copyright © 2017年 jinaiyuan. All rights reserved.
//

#ifndef ZXBDownloadError_h
#define ZXBDownloadError_h

typedef NS_ENUM(NSUInteger, ZXBDownloadError) {
    ZXBDownloadErrorNotEnoughFreeDiskSpace,
    ZXBDownloadErrorUnRegisterMoudle,
    ZXBDownloadErrorInvalidateParams,
    ZXBDownloadErrorMaxConcurrentNum,
    ZXBDownloadErrorItemUnderloading,
};

#endif /* ZXBDownloadError_h */
