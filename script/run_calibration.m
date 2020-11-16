function run_calibration(screen_info, reward_info, n_cal_pts)

reward_channel_index = reward_info.channel_index;
reward_size = reward_info.size;
reward_manager_type = reward_info.manager_type;

reward_serial_port = maybe_get_arduino_reward_serial_port( reward_manager_type, reward_info );

if nargin < 4
  n_cal_pts = 5;
end

target_size = 50; % px;
%n_cal_pts = 5;
skip_sync_tests = 1;

[ni_session, ni_scan_output] = maybe_make_ni_session_components( reward_manager_type );
reward_manager = ...
  make_reward_manager( reward_manager_type, ni_scan_output, reward_serial_port, reward_channel_index );

callback_data = make_callback_data( ni_scan_output, reward_manager, reward_size );
update_callback = @() update_func( callback_data );

Screen( 'Preference', 'skipsynctests', skip_sync_tests );
ListenChar( 2 );

try
    calibration.EYECALWin( screen_info, target_size, n_cal_pts ...
      , skip_sync_tests, update_callback );
    calibration.cleanup();
catch err
    calibration.cleanup();
    throw( err );
end

end

function [ni_session, ni_scan_output] = maybe_make_ni_session_components(reward_manager_type)

ni_session = [];
ni_scan_output = [];

switch ( reward_manager_type )
  case {'arduino', 'none'}
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
    
  case {'ni', 'none'}
    %
  otherwise
    error( 'Unhandled reward manager type "%s".', reward_manager_type );
end

end

function callback_data = make_callback_data(ni_scan_output, reward_manager, reward_size)

callback_data = ptb.Reference();
callback_data.Value.ni_scan_output = ni_scan_output;
callback_data.Value.reward_manager = reward_manager;
callback_data.Value.key_timer = ptb.Clock();
callback_data.Value.reward_size = reward_size;
callback_data.Value.key_timeout = 0.5;

end

function update_func(callback_data)

ni_scan_output = callback_data.Value.ni_scan_output;
reward_manager = callback_data.Value.reward_manager;
reward_size = callback_data.Value.reward_size;
key_timer = callback_data.Value.key_timer;
key_timeout = callback_data.Value.key_timeout;

if ( elapsed(key_timer) > key_timeout && ptb.util.is_key_down(ptb.keys.r) )
  if ( isa(reward_manager, 'serial_comm.SerialManager') )
    reward( reward_manager, 1, reward_size * 1e3 );    
    
  elseif ( ~isempty(reward_manager) )
    trigger( reward_manager, reward_size );
  end
  
  reset( key_timer )
end

if ( ~isempty(ni_scan_output) )
  update( ni_scan_output );
end

if ( ~isempty(reward_manager) )
  update( reward_manager );
end

end

function reward_manager = make_reward_manager(manager_type, ni_scan_output, serial_port, channel_index)

switch ( manager_type )
  case 'ni'
    reward_manager = make_ni_reward_manager( ni_scan_output, channel_index );
    
  case 'arduino'
    reward_manager = make_arduino_reward_manager( serial_port );
    
  case 'none'
    reward_manager = [];
    
  otherwise
    error( 'Unhandled reward manager type "%s".', manager_type );
end

end

function reward_manager = make_arduino_reward_manager(serial_port)

port = serial_port;
messages = struct();
channels = {'A'};

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

pct.util.add_reward_output_channels_to_ni_session( ni_session, ni_device_id );

end