//
//  mainController.h
//  SensorRecorder
//
//  Created by watanabekeisuke on 2017/05/21.
//  Copyright © 2017年 annolab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/cocoa.h>


#import <sys/ioctl.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/serial/IOSerialKeys.h>
#import <IOKit/IOBSD.h>
#import <IOKit/serial/ioss.h>

#import "stdio.h"

#define AVERAGE 60

@interface mainController : NSObject
{
    IBOutlet NSPopUpButton* serialPath_POPUP;
    IBOutlet NSButton* findSerial_BUTTON;
    IBOutlet NSTextField* log_TEXFIELD;
    IBOutlet NSButton* savePath_BUTTON;
    IBOutlet NSButton* recordStart_BUTTON;
    IBOutlet NSButton* recordStop_BUTTON;
    IBOutlet NSPopUpButton* dataMode_POPUP;
    
    NSMutableArray* serialPath_ARRAY;
    
    IBOutlet NSLevelIndicator* level_0;
    IBOutlet NSLevelIndicator* level_1;
    IBOutlet NSLevelIndicator* level_2;
    IBOutlet NSLevelIndicator* level_3;
    IBOutlet NSLevelIndicator* level_4;
    IBOutlet NSLevelIndicator* level_5;
    IBOutlet NSLevelIndicator* level_6;
    IBOutlet NSLevelIndicator* level_7;
    NSMutableArray* level_ARRAY;
    
    // serial variables
    int serial_Descriptor;
    struct termios gOriginalTTYAttrs;
    
    NSString* saveFile_STRING;
    
    FILE* fp;
    
    BOOL isStartRecord;
    
    unsigned char inValue[8];
    unsigned char prevValue[8];
    unsigned char aveValue[AVERAGE][8];
    
    NSTimer* readTimer_obj;
    NSDate* timeDate;
    double startTime;
    
    int dataMode;
    int aveCOUNTER;
}
@end


@interface mainController ( GUI )
- (IBAction)findSerialButton:(id)sender;
- (IBAction)selectSerialPath:(NSPopUpButton*)sender;
- (void)receiveData:(NSThread*)thread;
- (void)completeData:(NSThread*)thread;
- (IBAction)nameFile:(id)sender;
- (IBAction)recordButton:(NSButton*)sender;
- (IBAction)stopButton:(NSButton*)sender;
- (IBAction)dataMode:(NSPopUpButton*)sender;
@end
