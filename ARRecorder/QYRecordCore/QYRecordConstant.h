//
//  QYRecordConstant.h
//  ARRecorder
//
//  Created by Yuri Boyka on 2019/9/4.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#ifndef QYRecordConstant_h
#define QYRecordConstant_h
typedef NS_ENUM(NSInteger,ARFrameMode)
{
    autoAdjust,
    aspectFit,
    aspectFill,
};

typedef NS_ENUM(NSInteger,ARVideoFrameRate)
{
    autofps = 0,
    fps30 = 30,
    fps60 = 60,
};

typedef NS_ENUM(NSInteger,ARVideoOrientation)
{
    autoOrientation,
    alwaysPortrait,
    alwaysLandscape,
};

typedef NS_ENUM(NSInteger,RecordARMicrophonePermission)
{
    autoPermission,
    manual,
};

typedef NS_ENUM(NSInteger,ARRecordStatus)
{
    unkown,
    readyToRecord,
    recording,
    paused
};

typedef NS_ENUM(NSInteger,MicrophoneStatus)
{
    unknown,
    enabled,
    disabled,
};

typedef NS_ENUM(NSInteger,ARInputViewOrientation)
{
    portrait = 1,
    landscapeLeft = 3,
    landscapeRight = 4,
};
typedef NS_ENUM(NSInteger,ARInputViewOrientationMode)
{
    autoViewOrientationMode,
    all,
    manualViewOrientationMode,
    disabledViewOrientationMode,
};

#endif /* QYRecordConstant_h */
