//
//  mainController.m
//  SensorRecorder
//
//  Created by watanabekeisuke on 2017/05/21.
//  Copyright © 2017年 annolab. All rights reserved.
//

#import "mainController.h"

@implementation mainController

- (id)init
{
    self = [super init];
    
    NSLog(@"mainController init");
    
    serialPath_ARRAY = [[NSMutableArray alloc] init];
    level_ARRAY = [[NSMutableArray alloc] init];
    
    timeDate = [NSDate date];
    
    serial_Descriptor = -1;
    saveFile_STRING = nil;
    
    isStartRecord = NO;
    
    startTime = 0.0;
    fp = nil;
    
    dataMode = 0;
    
    for( int i = 0 ; i < AVERAGE ; i++ )
    {
        for( int j = 0 ; j < 8 ; j++ )
        {
            aveValue[i][j] = 0;
        }
    }
    
    aveCOUNTER = 0;
    
    return self;
}

- (void)awakeFromNib
{
    NSLog(@"mainController AFN");
    // GUI
    findSerial_BUTTON.enabled = YES;
    serialPath_POPUP.enabled = NO;
    savePath_BUTTON.enabled = NO;
    recordStart_BUTTON.enabled = NO;
    recordStop_BUTTON.enabled = NO;

    [level_ARRAY addObject:level_0];
    [level_ARRAY addObject:level_1];
    [level_ARRAY addObject:level_2];
    [level_ARRAY addObject:level_3];
    [level_ARRAY addObject:level_4];
    [level_ARRAY addObject:level_5];
    [level_ARRAY addObject:level_6];
    [level_ARRAY addObject:level_7];
    
    level_6.alphaValue = 0.2;
    level_7.alphaValue = 0.2;
    
    [serialPath_POPUP removeAllItems];
    
    [dataMode_POPUP removeAllItems];
    [dataMode_POPUP addItemsWithTitles:[NSArray arrayWithObjects:@"RAW data", @"Delta", @"Average Delta", nil]];
}



@end
