//
//  PBViewController.m
//  PBNest
//
//  Created by Haifisch on 7/31/13.
//  Copyright (c) 2013 Haifisch. All rights reserved.
//

#import "PBViewController.h"

@interface PBViewController () <PBPebbleCentralDelegate>


@end

@implementation PBViewController {
    PBWatch *_targetWatch;
}

-(void)refreshAction:(id)sender {
    if (_targetWatch == nil || [_targetWatch isConnected] == NO) {
        [[[UIAlertView alloc] initWithTitle:nil message:@"No connected watch!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
       
        return;
    }
    
    __block NSDictionary *dictRoot = nil;
    __block NSNumber *targetTemperature = nil;
    
    // Fetch the Nest's attributes
    NSString *apiURLString = [NSString stringWithFormat:@"http://%@/nest/getTemp.php?email=%@&password=%@", self.hostField.text, self.usernameField.text, self.passwordField.text];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:apiURLString]];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            httpResponse = (NSHTTPURLResponse *) response;
        }
        
        // NSURLConnection's completionHandler is called on the background thread.
        // Prepare a block to show an alert on the main thread:
        __block NSString *message = @"";
        void (^showAlert)(void) = ^{
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
           //     [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                 NSLog(@"%@",message);
            }];
           
        };
        
        // Check for error or non-OK statusCode:
        if (error || httpResponse.statusCode != 200) {
            message = @"Error fetching Nest attributes";
            showAlert();
            return;
        }
        
        // Parse the JSON response:
        NSError *jsonError = nil;
        NSDictionary *root = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        dictRoot = root;
        @try {
            if (jsonError == nil && root) {
                // TODO: type checking / validation, this is really dangerous...
                
                // Set the number format
                NSNumberFormatter *numberFormat = [[NSNumberFormatter alloc] init ];
                [numberFormat setNumberStyle:NSNumberFormatterDecimalStyle];
                [numberFormat setMaximumFractionDigits:0];
                
                // Get the current temperature scale (Fahrenheit or Celsius)
                NSString *temperatureScale = root[@"scale"];
                
                // Get the current temperature:
                NSDictionary *current_state = [root valueForKey:@"current_state"];
                NSNumber *temperatureNumber = current_state[@"temperature"];
                
                // Format the current temperature to be sent to watch
                NSString *formattedTemp = @"Current: ";
                formattedTemp = [formattedTemp stringByAppendingString:[numberFormat stringFromNumber:temperatureNumber]];
                formattedTemp = [formattedTemp stringByAppendingString:@" \u00B0"];  // appends a degree symbol
                formattedTemp = [formattedTemp stringByAppendingString:temperatureScale];
                
                // Get the target temperature:
                NSDictionary *target = [root valueForKey:@"target"];
                NSNumber *targetTemperatureNumber = target[@"temperature"];
                targetTemperature = targetTemperatureNumber;
                
                // Format the target temperature to be sent to watch
                NSString *formattedTargetTemp = @"Target: ";
                formattedTargetTemp = [formattedTargetTemp stringByAppendingString:[numberFormat stringFromNumber:targetTemperatureNumber]];
                formattedTargetTemp = [formattedTargetTemp stringByAppendingString:@" \u00B0"];
                formattedTargetTemp = [formattedTargetTemp stringByAppendingString:temperatureScale];
                
                // Debugging output
                message = formattedTemp;
                message = [message stringByAppendingString:@"\n"];
                message = [message stringByAppendingString:formattedTargetTemp];
                showAlert();
                

                // Send data to watch:
                // See demos/feature_app_messages/weather.c in the native watch app SDK for the same definitions on the watch's end:
                //NSNumber *iconKey = @(0); // This is our custom-defined key for the icon ID, which is of type uint8_t.
                NSNumber *currentTemperatureKey = @(1); // This is our custom-defined key for the current temperature string.
                NSNumber *targetTemperatureKey = @(0); // This is out custom-defined key for the target temperature string.
                // NSNumber *humidityKey = @(0); // This is our custom-defined key for the humidity string.
                // NSNumber *modeKey = @(2); // This is our custom-defined key for the humidity string.
                NSDictionary *update = @{
                                          currentTemperatureKey:[NSString stringWithFormat:@"%@", formattedTemp],
                                          targetTemperatureKey:[NSString stringWithFormat:@"%@", formattedTargetTemp]
                                          //humidityKey:[NSString stringWithFormat:@"%@", formattedHumidity],
                                          //modeKey:houseMode
                                        };
                [_targetWatch appMessagesPushUpdate:update onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
                    message = error ? [error localizedDescription] : @"Update to watch sent!";
                    showAlert();
                }];
                
                return;
            }
        }
        @catch (NSException *exception) {
        }
        message = @"Error parsing retrieval response";
        showAlert();
        
        
        
    }];
    
    
    
    // Set the temperature
    
    
        // Send data to web server
        [_targetWatch appMessagesAddReceiveUpdateHandler:^BOOL(PBWatch *watch, NSDictionary *updateFromWatch) {
            
            // NSURLConnection's completionHandler is called on the background thread.
            // Prepare a block to show an alert on the main thread:
            __block NSString *message = @"";
            void (^showAlert)(void) = ^{
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    //     [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                    NSLog(@"%@",message);
                }];
                
            };
            
            message = @"Button pressed! \n";
            
            // Increment temperature by 1
            int value = [targetTemperature intValue];
            NSNumber *newTemperature = [NSNumber numberWithInt:value+1];
            NSString *strNewTemp = [newTemperature stringValue];
            
            // Show new target temperature
            message = [message stringByAppendingString:@"New target temperature: "];
            message = [message stringByAppendingString:strNewTemp];
            showAlert();
            
            
            /*NSString *apiPOSTURLString = [NSString stringWithFormat:@"http://%@/nest/setTemp.php?email=%@&password=%@&tempInt=%@", self.hostField.text, self.usernameField.text, self.passwordField.text, strNewTemp];
            NSURLRequest *POSTrequest = [NSURLRequest requestWithURL:[NSURL URLWithString:apiPOSTURLString]];
            NSOperationQueue *POSTqueue = [[NSOperationQueue alloc] init];
            [NSURLConnection sendAsynchronousRequest:POSTrequest queue:POSTqueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                NSHTTPURLResponse *httpResponse = nil;
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    httpResponse = (NSHTTPURLResponse *) response;
                }
                
                // Check for error or non-OK statusCode:
                if (error || httpResponse.statusCode != 200) {
                    message = @"Error setting temperature";
                    showAlert();
                    return;
                }
                
                
                
            }];*/
            
            
            return true;
        }];

}

- (void)setTargetWatch:(PBWatch*)watch {
    _targetWatch = watch;
    
    // NOTE:
    // For demonstration purposes, we start communicating with the watch immediately upon connection,
    // because we are calling -appMessagesGetIsSupported: here, which implicitely opens the communication session.
    // Real world apps should communicate only if the user is actively using the app, because there
    // is one communication session that is shared between all 3rd party iOS apps.
    
    // Test if the Pebble's firmware supports AppMessages / Weather:
    [watch appMessagesGetIsSupported:^(PBWatch *watch, BOOL isAppMessagesSupported) {
        if (isAppMessagesSupported) {
            // Configure our communications channel to target the weather app:
            // See demos/feature_app_messages/weather.c in the native watch app SDK for the same definition on the watch's end:
            uint8_t bytes[] = {0x42, 0xc8, 0x6e, 0xa4, 0x1c, 0x3e, 0x4a, 0x7, 0xb8, 0x89, 0x2c, 0xcc, 0xca, 0x91, 0x41, 0x98};
            NSData *uuid = [NSData dataWithBytes:bytes length:sizeof(bytes)];
            [watch appMessagesSetUUID:uuid];
            
            NSString *message = [NSString stringWithFormat:@"Yay! %@ supports AppMessages :D", [watch name]];
            //[[[UIAlertView alloc] initWithTitle:@"Connected!" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            NSLog(@"%@",message);
        } else {
            
            NSString *message = [NSString stringWithFormat:@"Blegh... %@ does NOT support AppMessages :'(", [watch name]];
            //[[[UIAlertView alloc] initWithTitle:@"Connected..." message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            NSLog(@"%@",message);
        }
    }];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    // We'd like to get called when Pebbles connect and disconnect, so become the delegate of PBPebbleCentral:
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"noisy_grid"]];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults objectForKey:@"username"] != NULL && [defaults objectForKey:@"password"]){
        self.usernameField.text = [defaults objectForKey:@"username"];
        self.passwordField.text = [defaults objectForKey:@"password"];
        wat = [NSTimer scheduledTimerWithTimeInterval:[self.timeInt.text integerValue]
                                         target:self
                                       selector:@selector(refreshAction:)
                                       userInfo:nil
                                        repeats:YES];
        }else {
       [[[UIAlertView alloc] initWithTitle:@"Oops!" message:@"Please fill in your user data, then click the button!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    [[PBPebbleCentral defaultCentral] setDelegate:self];
    
    // Initialize with the last connected watch:
    [self setTargetWatch:[[PBPebbleCentral defaultCentral] lastConnectedWatch]];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
/*
 *  PBPebbleCentral delegate methods
 */

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidConnect:(PBWatch*)watch isNew:(BOOL)isNew {
    [self setTargetWatch:watch];
    wat = [NSTimer scheduledTimerWithTimeInterval:[self.timeInt.text integerValue]
                                           target:self
                                         selector:@selector(refreshAction:)
                                         userInfo:nil
                                          repeats:YES];
}

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidDisconnect:(PBWatch*)watch {
    [wat invalidate];
    [[[UIAlertView alloc] initWithTitle:@"Disconnected!" message:[watch name] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    if (_targetWatch == watch || [watch isEqual:_targetWatch]) {
        [self setTargetWatch:nil];
    }
    [watch wake];
}
-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.usernameField.text forKey:@"username"];
    [defaults setObject:self.passwordField.text forKey:@"password"];
    [defaults synchronize];
    [textField resignFirstResponder];
    return YES;
}
- (IBAction)updateStart:(id)sender {
    NSLog(@"stopping");
    [wat invalidate];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.usernameField.text forKey:@"username"];
    [defaults setObject:self.passwordField.text forKey:@"password"];
    [defaults synchronize];
    wat = [NSTimer scheduledTimerWithTimeInterval:[self.timeInt.text integerValue]
                                           target:self
                                         selector:@selector(refreshAction:)
                                         userInfo:nil
                                          repeats:YES];
    NSLog(@"starting");
}
@end
