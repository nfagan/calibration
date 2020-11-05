function EYECALWin(screen_index, full_rect, cal_rect, target_size, n_cal_pts ...
  , skip_sync_tests, update_callback)   % modified from eyecal_gka

import calibration.sharedWorkspace;
import calibration.escapeHandler;
import calibration.sleepWithKbCheck;

KbName('UnifyKeyNames' );

poll_time = 0.01; % time between consecutive key polling events

target_size = [ -target_size, -target_size; target_size, target_size ];
% adjust_x = full_rect(1);
adjust_x = 0;

% addpath( fullfile(fileparts(which(mfilename)), 'images') );
img_path = fullfile( fileparts(which('calibration.EYECALWin')), 'images' );
Pictures=1; %Enter 1 to show Monkey Pictures, Enter 0 for original squares
NumMonkeys=5; %Number of monkeys to show per trial/fixation point

JuiceAmount_cal = 200; %amount
RewardTrial = 'j';  %if null, use 'j' to reward them manually [200 ms] (could be more effective)
dummymode = 0; % Abort if false input
% Define some basic constants:
const.monkeyScreen = screen_index;
const.nScreens = 1;
const.interTrial = 1; %seconds
const.bgColor = [0 0 0];

if ~EyelinkInit(dummymode) %Initialize Eyelink
    fprintf('Eyelink Init aborted.\n');
    cleanup;
    return;
end
if Eyelink('IsConnected')~=1 && ~dummymode %Verify connection to Eyelink
    cleanup;
    return;
end

if ( skip_sync_tests )
  Screen( 'Preference', 'SkipSyncTests', 1 );
end

[window, wRect] = Screen( 'OpenWindow', const.monkeyScreen, const.bgColor, full_rect );%#ok<*NASGU>

% blankScreen = Screen('OpenOffscreenWindow', const.monkeyScreen, const.bgColor, [], 32);
const.screenCenter = round([mean(wRect([1 3])) mean(wRect([2 4]))]);
startEyelinkCal(cal_rect, n_cal_pts); % Open communications with Eyelink and put it into calibration mode


% Set up keys and functions to handle keypresses during the calibration
% task:
%     To add more key bindings, add elements to the keyHandlers array with
%     these fields:
%     key: The key to be pressed
%     func: The function to be called when the key is pressed. Can be a
%           function handle (ie, @ followed by the name of the function),
%           or a cell array where the first element is a function handle
%           and the subsequent elements are arguments to the function (eg.,
%           {@disp, 'Hello.'} would call "disp('hello')" when the key is
%           pressed)
%     wake: If set to true, will cause calls to sleepWithKbCheck to
%           terminate immediately when the key is pressed
%     capture: Capture output from the called functions.
%     See "help sleepWithKbCheck" for more information.

%Initalize juice delivery system
%DIO = digitalio('nidaq','1');
%lines = addline(DIO,0:7,3,'out'); 
%digOut = setupDigitalOut_swc;

KbName('UnifyKeyNames');
keyHandlers(1).key = 'ESCAPE'; % Terminate the task
keyHandlers(1).func = @escapeHandler;  % keyHandlers(1).func = @(x,y,z)(<cmd>) or
keyHandlers(1).wake = true;            % keyHandlers(1).func = @Name Of Function
keyHandlers(2).key = 'j';
% keyHandlers(3).key = 'r';
% keyHandlers(3).func = key_callback;
%keyHandlers(2).func = @()(fprintf(serialthing,'%s','2'));  % or keyHandlers(2).func = {@J1, 100}; ... using empty func, (), is slightly fater

% Screen('CopyWindow',blankScreen,window,wRect,wRect); % Sync with the screen
Screen('Flip',window);

% Create a "shared workspace" to store data that needs to be accessed by multiple functions, but isn't appropriate for passing as arguments:
sharedWorkspace EYECALWin -clear;
sharedWorkspace('EYECALWin', 'keepGoing', true);

trialNum = 0;

disp('eyecal_gka will display targets in the positions Eyelink expects.');
disp('Simple accept fixation on the Eyelink system, and on the next');
disp('trial, the target will appear in the next location.');
disp('Once you have accepted the entire calibration, the script will exit.');
disp('Or, press escape to abort early.');

trial_timer = ptb.Clock();

%% BEGIN SESSION
while sharedWorkspace('EYECALWin','keepGoing') %global workspace saves values outside of the function
    trialNum = trialNum+1;
    % Beep:
    %%sound(sin(1:.2:400));
    %% Square targets
    try
        a=randperm(10);
        imgfile{1}='m1.jpg'; %Load images into memory as cell array
        imgfile{2}='m2.jpg';
        imgfile{3}='m3.jpg';
        imgfile{4}='m4.jpg';
        imgfile{5}='m5.jpg';
        imgfile{6}='m6.jpg';
        imgfile{7}='m7.jpg';
        imgfile{8}='m8.jpg';
        imgfile{9}='m9.jpg';
        imgfile{10}='m10.jpg';
        imgfile = cellfun( @(x) fullfile(img_path, x), imgfile, 'un', false );
        d=1; %multiplier
%             target_size  = [-50 -50; 50  50].*d;
        %target_size  = [-100 -100; 100  100].*d;
        %             target_size  = [-52 -52; 52  52];
        [dummy, targX, targY] = Eyelink('TargetCheck');
        targRect = shiftPoints(target_size, [targX targY])';
        targRect = targRect(:)';
        targRect([1, 3]) = targRect([1, 3]) - adjust_x;

%             disp( targRect );
        for b=1:NumMonkeys, %Number of monkeys to show per trial               
          imload=imread(imgfile{a(b)},'jpg');
          Screen('PutImage',window,imload,targRect);
          Screen('Flip', window);
          
          reset( trial_timer );
          while ( elapsed(trial_timer) < 0.5 )
            update_callback();
          end
        end
    catch err
        throw( err );
%             Screen('CloseAll');
%             disp('Picture Error');
    end
    if Eyelink('CurrentMode')~=10
        break;
    end
    %     % Beep:
    %     %%sound(sin(1:.2:400));
    %     % Wait 1 second:
     sleepWithKbCheck(2,keyHandlers, poll_time, update_callback);
     sleepWithKbCheck(1,keyHandlers, poll_time, update_callback);
    if ~sharedWorkspace('EYECALWin','keepGoing');
        break;
    end       
    
    % if RewardTrial % Reward

      %   fprintf(serialthing,'%s','2');
     %end    
    %fprintf('TRIAL %d CORRECT\n', trialNum);
    % Clear the screen:
%     Screen('CopyWindow', blankScreen, window, wRect, wRect);
    Screen('Flip', window);
    % Wait the intertrial interval:
    sleepWithKbCheck(const.interTrial,keyHandlers, poll_time, update_callback);
%     KbCheck(const.interTrial,keyHandlers);
    if ~sharedWorkspace('EYECALWin','keepGoing');
        break;
    end   
end
%Clean up the screen
Screen('Closeall');
%Eyelink('Shutdown');

% HELPER FUNCTIONS
function startEyelinkCal(winSize, n_cal_pts)
% Start calibration on Eyelink. winSize is the size of the stimulus window
% being used (ie, the screenRect output from Screen('OpenWindow',...));
% nCalPoints is the number of calibration points to use (should be 3, 5, or
% 9).
% Eyelink('Command', 'formatstring', [...])
Eyelink('command','screen_pixel_coords = %d %d %d %d', winSize(1), winSize(2), winSize(3), winSize(4) );
calType = ['HV' num2str(n_cal_pts)];
Eyelink('Command', ['calibration_type = ' calType]);
Eyelink('StartSetup');
cont = true;
% Wait until Eyelink actually enters Setup mode (otherwise the
% SendKeyButton command below can happen too quickly and won't actually put
% us in calibration mode):
while cont && Eyelink('CurrentMode')~=2
    % [keyIsDown, secs, keyCode, deltaSecs] = KbCheck([deviceNumber])
    [keyIsDown,secs,keyCode] = KbCheck;
    if keyIsDown && keyCode(KbName('escape'))
        disp('Aborted while waiting for Eyelink!');
        cont = false;
    end
end
% Magic words: Send the keypress 'c' to select "Calibrate"
Eyelink('SendKeyButton',double('c'),0,10);

function newPoints = shiftPoints(points, shift)
% Points should be N-by-2 for N points, shift should be 1-by-2
%newPoints = bsxfun(@plus,points,shift);
shift = repmat(shift, size(points,1), 1);
newPoints = points + shift;


% Cleanup routine:
function cleanup
% Shutdown Eyelink:
Eyelink('Shutdown');

% Close window:
sca;
commandwindow;
% Restore keyboard output to Matlab:
ListenChar(0);

