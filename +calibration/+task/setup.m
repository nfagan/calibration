function program = setup(display_opts, calibration_rect, stim_info, reward_info)

program = ptb.Reference();
program.Destruct = @(program) calibration.task.shutdown( program );

set_input_listen_state();

calibration_manager = make_calibration_manager( calibration_rect );
start( calibration_manager );

reward_info = extend_reward_info( reward_info );
reward_manager_type = get_reward_manager_type( reward_info );
serial_port = maybe_get_arduino_reward_serial_port( reward_manager_type, reward_info );

main_window = make_window( display_opts );
states = make_states( program );
task = make_task( program );
stimuli = make_images( main_window, stim_info );

[ni_session, ni_scan_output] = maybe_make_ni_session_components( reward_manager_type );
reward_manager = ...
  make_reward_manager( reward_manager_type, ni_scan_output, serial_port, reward_info.channel_index );

program.Value.calibration_manager = calibration_manager;
program.Value.main_window = main_window;
program.Value.states = states;
program.Value.task = task;
program.Value.stimuli = stimuli;
program.Value.ni_session = ni_session;
program.Value.ni_scan_output = ni_scan_output;
program.Value.reward_manager = reward_manager;
program.Value.reward_info = reward_info;

end

function set_input_listen_state()

HideCursor();
ListenChar( 2 );

end

function stimuli = make_images(window, stim_info)

this_file = which( 'calibration.task.setup' );
calib_folder = fileparts( fileparts(this_file) );
images_folder = fullfile( calib_folder, 'images' );

image_files = shared_utils.io.find( images_folder, 'jpg' );
image_matrices = cellfun( @imread, image_files, 'un', 0 );

stimuli = cell( size(image_matrices) );

for i = 1:numel(image_matrices)
  image = ptb.Image();
  image = create( image, window, image_matrices{i} );
  
  stimulus = ptb.stimuli.Rect();
  stimulus.FaceColor = image;
  
  if ( isfield(stim_info, 'size') )
    stimulus.Scale = stim_info.size;
  end
  if ( isfield(stim_info, 'units') )
    stimulus.Scale.Units = stim_info.units;
  end
  
  stimulus.Position.Units = 'normalized';
  stimulus.Position = 0.5;
  
  stimuli{i} = stimulus;
end

end

function task = make_task(program)

task = ptb.Task();
task.Duration = inf;
task.Loop = @(task) calibration.task.loop( task, program );
task.exit_on_key_down( ptb.keys.esc() );

end

function states = make_states(program)

states = containers.Map();
states('present_images') = calibration.task.states.present_images( program );

end

function obj = make_window(display_opts)

obj = ptb.Window();
obj.Index = display_opts.index;
obj.Rect = display_opts.rect;
obj.SkipSyncTests = display_opts.skip_sync_tests;

open( obj );

end


function reward_info = extend_reward_info(reward_info)

reward_info.key_timer = ptb.Clock();
reward_info.key_timeout = 0.5;

end

function obj = make_calibration_manager(calibration_rect)

obj = calibration.EyelinkCalibration( calibration_rect );

end

function [ni_session, ni_scan_output] = maybe_make_ni_session_components(reward_manager_type)

ni_session = [];
ni_scan_output = [];

switch ( reward_manager_type )
  case 'arduino'
    %
  case 'ni'
    ni_session = make_ni_daq_session();
    ni_scan_output = make_ni_scan_output( ni_session );
    
  otherwise
    error( 'Unhandled reward manager type "%s".', reward_manager_type );
end

end

function serial_port = maybe_get_arduino_reward_serial_port(reward_manager_type, reward_info)

serial_port = '';

switch ( reward_manager_type )
  case 'arduino'
    if ( ~isfield(reward_info, 'serial_port') )
      error( 'Required field `serial_port` is missing.' );
    end
    
    serial_port = reward_info.serial_port;
    
  case 'ni'
    %
  otherwise
    error( 'Unhandled reward manager type "%s".', reward_manager_type );
end

end

function reward_manager = make_reward_manager(manager_type, ni_scan_output, serial_port, channel_index)

switch ( manager_type )
  case 'ni'
    reward_manager = make_ni_reward_manager( ni_scan_output, channel_index );
    
  case 'arduino'
    reward_manager = make_arduino_reward_manager( serial_port );
    
  otherwise
    error( 'Unhandled reward manager type "%s".', manager_type );
end

end

function reward_manager = make_arduino_reward_manager(serial_port)

port = serial_port;
messages = struct();
channels = serial.channels;

reward_manager = serial_comm.SerialManager( port, messages, channels );
start( reward_manager );

end

function reward_manager = make_ni_reward_manager(ni_scan_output, channel_index)

reward_manager = ptb.signal.SingleScanOutputPulseManager( ni_scan_output, channel_index );

end

function ni_scan_output = make_ni_scan_output(ni_session)

ni_scan_output = ptb.signal.SingleScanOutput( ni_session );
ni_scan_output.PersistOutputValues = true;

end

function ni_session = make_ni_daq_session()

ni_session = daq.createSession( 'ni' );
ni_device_id = pct.util.get_ni_daq_device_id();

addAnalogOutputChannel( ni_session, ni_device_id, 0, 'Voltage' );
addAnalogOutputChannel( ni_session, ni_device_id, 1, 'Voltage' );

end

function type = get_reward_manager_type(reward_info)

type = 'ni';

if ( isstruct(reward_info) && isfield(reward_info, 'manager_type') )
  type = ...
    validatestring( reward_info.manager_type, {'ni', 'arduino'}, mfilename, 'manager_type' );
end

end