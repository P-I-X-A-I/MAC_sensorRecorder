

#import "mainController.h"

@implementation mainController ( GUI )

- (IBAction)findSerialButton:(id)sender
{
    NSLog(@"find serial");
    
    [serialPath_ARRAY removeAllObjects];
    
    io_object_t serialPort;
    io_iterator_t serialPort_Iterator;
    
    // search all serial ports
    IOServiceGetMatchingServices( kIOMasterPortDefault,
                                 IOServiceMatching( kIOSerialBSDServiceValue),
                                &serialPort_Iterator);



    // add serial path
    while(( serialPort = IOIteratorNext( serialPort_Iterator )))
    {
        NSString* tempString = (__bridge NSString*)IORegistryEntryCreateCFProperty(serialPort, CFSTR(kIOCalloutDeviceKey), kCFAllocatorDefault, 0);
        
        [serialPath_ARRAY addObject:tempString];
        
        IOObjectRelease( serialPort );
    }
    
    IOObjectRelease( serialPort_Iterator );
    
    
    // add path
    [serialPath_POPUP addItemsWithTitles:serialPath_ARRAY];
    
    
    
    serialPath_POPUP.enabled = YES;
}



- (IBAction)selectSerialPath:(NSPopUpButton *)sender
{
    NSLog(@"select path popup");
    
    NSString* pathString = [sender titleOfSelectedItem];

    // check if it contains "usb" characters
    NSRange tempRange = [pathString rangeOfString:@"usb"];
    if( tempRange.location == NSNotFound )
    {
        log_TEXFIELD.stringValue = @"this is not usb port";
        return;
    }
    
    
    // if
    if( serial_Descriptor != -1 )
    {
        close( serial_Descriptor );
        serial_Descriptor = -1;
        sleep(0.5);
    }
    
    
    
    // variables
    struct termios options;
    unsigned long mics = 5;
    int success;
    const char* path_Cstring = [pathString cStringUsingEncoding:NSUTF8StringEncoding];
    
    
    // open port
    serial_Descriptor = open( path_Cstring, O_RDWR | O_NOCTTY | O_SYNC | O_NONBLOCK );
    
    if( serial_Descriptor == -1 )
    {
        log_TEXFIELD.stringValue = @"This port can't be opened.";
        return;
    }
    
    
    
    // TIOCEXCL causes blocking of non-root processes on serial port
    success = ioctl( serial_Descriptor, TIOCEXCL );
    if( success == -1 ){ NSLog(@"TIOCEXCL error, return"); return; }
    success = fcntl( serial_Descriptor, F_SETFL, 0 );
    if( success == -1 ){ NSLog(@"F_SETFL error, return"); return; }
    
    
    
    // get current option
    success = tcgetattr( serial_Descriptor, &gOriginalTTYAttrs);
    if( success == -1 ){ NSLog(@"get attr error, return"); return; }
    
    
    
    // copy original attrs and set all I/O flags to invalid
    options = gOriginalTTYAttrs;
    cfmakeraw( &options );
    
    
    // set tty attribute
    success = tcsetattr( serial_Descriptor, TCSANOW, &options );
    if( success == -1 ){ NSLog(@"set TCSANOW error. return"); return;}
    
    
    // set baud rate
    speed_t baudRate = 9600;
    success = ioctl( serial_Descriptor, IOSSIOSPEED, &baudRate );
    if( success == -1 ){ NSLog(@"set baud rate error. return"); return; }
    
    
    
    // set latency
    success = ioctl( serial_Descriptor, IOSSDATALAT, &mics );
    if( success == -1 ){ NSLog(@"set latency error, return"); return; }
    
    sleep(1.0);
    
    log_TEXFIELD.stringValue = @"Serial port is opened.";
    
    
    // GUI
    savePath_BUTTON.enabled = YES;
    findSerial_BUTTON.enabled = NO;
    serialPath_POPUP.enabled = NO;
    
    
    // set callback
    [self performSelectorInBackground:@selector(receiveData:) withObject:[NSThread currentThread]];
    
}

- (void)receiveData:(NSThread*)thread
{
    unsigned char receiveBuf;
    long numBytes = 0;
    
    int COUNT = 0;
    BOOL isOK = NO;
    
    while( 1 )
    {
        numBytes = read( serial_Descriptor, &receiveBuf, 1 );
        
        if( numBytes > 0 )
        {
            switch (receiveBuf)
            {
                case 251: // start
                    COUNT = 0;
                    isOK = NO;
                    break;
                
                case 255: // end
                    if( COUNT == 8 )
                    {
                        // successfully end
                        isOK = YES;
                    }
                    else
                    {
                        // some error.
                    }
                    break;
                    
                    
                default:
                    COUNT++;
                    if( COUNT <= 8 )
                    {
                        inValue[COUNT-1] = receiveBuf;
                    }
                    
                    break;
            }
            
            if( isOK )
            {
                [self performSelectorOnMainThread:@selector(completeData:) withObject:nil waitUntilDone:NO];
            }
            
        }
        else
        {
            break;
        }
    }
    
    if( serial_Descriptor != -1 )
    {
        close(serial_Descriptor);
        serial_Descriptor = -1;
    }
}


- (void)completeData:(NSThread *)thread
{
    for( int i = 0 ; i < 8 ; i++ )
    {
        NSLevelIndicator* tempLevel = [level_ARRAY objectAtIndex:i];
        
        int tempAveVal = 0;

        
        if(dataMode == 0 )
        {
            tempLevel.intValue = inValue[i];
        }
        else if( dataMode == 1 )
        {
            tempLevel.intValue = inValue[i] - prevValue[i];
        }
        else if( dataMode == 2 )
        {
            
            for( int j = 0 ; j < AVERAGE ; j++ )
            {
                tempAveVal += aveValue[j][i];
            }
            
            tempAveVal = tempAveVal / AVERAGE;
            
            tempLevel.intValue = inValue[i] - tempAveVal;
        }
        
        
        
        
        if( isStartRecord )
        {
            int recordVal = 0;
            
            // timestamp
            if( i == 0 )
            {
                double timeVal = [NSDate timeIntervalSinceReferenceDate] - startTime;
                fprintf(fp, "%f/", timeVal);
            }
            
            if( dataMode == 0 )
            {
                recordVal = inValue[i];
            }
            else if( dataMode == 1 )
            {
                recordVal = inValue[i] - prevValue[i];
            }
            else if( dataMode == 2 )
            {
                recordVal = inValue[i] - tempAveVal;
            }
            
            if( i >= 0 && i <= 5)
            {
                fprintf(fp, "%d:", inValue[i]);
                fprintf(fp, "%d/", recordVal );
            }
            // end code
            if( i == 7 )
            {
             //   printf("\n");
                fprintf( fp, "end\n" );
            }
        } // isStartRecording
        
        
        aveValue[aveCOUNTER][i] = inValue[i];
        
        prevValue[i] = inValue[i];
    }// for
    
    aveCOUNTER++;
    if(aveCOUNTER > AVERAGE-1
       )
    {
        aveCOUNTER = 0;
    }
}


- (IBAction)nameFile:(id)sender
{
    // save panel
    NSSavePanel* tempSavePanel = [NSSavePanel savePanel];
    NSArray* allowedFileTypes = [NSArray arrayWithObjects:@"txt", nil];
    [tempSavePanel setAllowedFileTypes:allowedFileTypes];
    
    // check button state
    NSInteger pressedButton = [tempSavePanel runModal];
    
    
    // condition
    if(pressedButton == NSModalResponseOK)
    {
        saveFile_STRING = [[NSString alloc] initWithString:[[tempSavePanel URL] path]];
        NSLog(@"OK %@", saveFile_STRING);

        
        // open file
        if( fp != nil )
        {
            fclose(fp);
        }
        
        fp = fopen( [saveFile_STRING cStringUsingEncoding:NSUTF8StringEncoding], "w");
        
        
        
        
        // GUI
        recordStart_BUTTON.enabled = YES;
        savePath_BUTTON.enabled = NO;
    }
    else if( pressedButton == NSModalResponseCancel)
    {
        NSLog(@"cancel");
    }
    
    
    
    
}


- (IBAction)recordButton:(NSButton*)sender
{
    findSerial_BUTTON.enabled = NO;
    serialPath_POPUP.enabled = NO;
    savePath_BUTTON.enabled = NO;
    recordStart_BUTTON.enabled = NO;
    recordStop_BUTTON.enabled = YES;
    
    isStartRecord = YES;
    
    startTime = [NSDate timeIntervalSinceReferenceDate];
}

- (IBAction)stopButton:(NSButton*)sender
{
    findSerial_BUTTON.enabled = NO;
    serialPath_POPUP.enabled = NO;
    savePath_BUTTON.enabled = YES;
    recordStart_BUTTON.enabled = NO;
    recordStop_BUTTON.enabled = NO;
    
    fclose(fp);
    
    isStartRecord = NO;
}

- (IBAction)dataMode:(NSPopUpButton*)sender
{
    int index = (int)sender.indexOfSelectedItem;
    dataMode = index;
}

@end
