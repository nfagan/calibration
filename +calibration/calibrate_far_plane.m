function keys = calibrate_far_plane(led_comm_port, key_code_map, light_dur)

%   CALIBRATE_FAR_PLANE -- Calibrate with distant LEDs.
%
%     keys = ... calibrate_far_plane( 1:3 ) enables the first 3 LED
%     far-plane targets. Pressing 1, 2, or 3 on the number pad activates
%     that target, and lights up the corresponding LED. Pressing return
%     captures the current gaze coordinates and associates them with
%     the active target, returning the results in `keys`.
%
%     IN:
%       - `key_code_map` (containers.Map)
%     OUT:
%       - `keys` (struct)

tracker = [];
led_comm = [];

keys = struct();
    
try
  fprintf( '\n Initializing ... ' );

  tracker = EyeTracker( '~', cd, 0 );
  tracker.init();
  
  led_comm = make_led_comm( led_comm_port );

  KbName( 'UnifyKeyNames' );
  ListenChar( 2 );
  
  key_code_map_k = key_code_map.keys();
  key_code_map_v = key_code_map.values();
  num_pad_zero = 96;

  for i = 1:numel(key_code_map_k)
    key_n = key_code_map_v{i} - num_pad_zero;
    
    if ( key_n == 0 )
      key_n = 10;
    end
    
    keys.(sprintf('key__%d', key_n)) = struct( ...
        'coordinates', [0, 0] ...
      , 'was_pressed', false ...
      , 'key_code', key_code_map_v{i} ...
      , 'led_index',key_code_map_k{i} ...
      , 'timer', NaN ...
      );
  end
  
  if ( nargin < 2 )
    LED_DURATION = 1000; % ms
  else
    LED_DURATION = light_dur;
  end

  key_debounce_time = 0.2; % s
  accept_key = KbName( 'return' );
  key_fields = fieldnames( keys );
  active_field = key_fields{1};
  
  target_size = 20;
  first_targ_color = 2;
  target_colors = first_targ_color:(first_targ_color+numel(key_fields)-1);
  
  fprintf( 'Done.' );
  
  task();
  cleanup();
catch err
  brains.util.print_error_stack( err );
  cleanup();
end

%
% task
%

function task()

fprintf( '\n Listening ...' );
  
while ( true )  
  last_coords = tracker.coordinates;
  tracker.update_coordinates();
  led_comm.update();
  if ( isempty(tracker.coordinates) )
    tracker.coordinates = last_coords;
  end
  should_abort = handle_key_press();
  if ( should_abort ), break; end
end

all_pressed = true;

for ii = 1:numel(key_fields)
  if ( ~keys.(key_fields{ii}).was_pressed )
    fprintf( '\nWARNING: ''%s'' was never registered.', key_fields{ii} );
    all_pressed = false;
  end
end

if ( all_pressed )
  fprintf( '\n OK: All targets registered.' );
end

end

%
% key press handling
%

function should_abort = handle_key_press()
  should_abort = false;
  known_key = false;
  
  [key_pressed, ~, key_code] = KbCheck();
  
  if ( ~key_pressed ), return; end
  
  if ( key_code(ptb.keys.esc()) )
    should_abort = true;
    return; 
  end
  
  for i_ = 1:numel(key_fields)
    current = keys.(key_fields{i_});
    if ( key_code(current.key_code) )
      if ( isnan(current.timer) || toc(current.timer) > key_debounce_time )
        fprintf( '\n Activated ''%s''.', key_fields{i_} );
        led_comm.light( current.led_index, LED_DURATION );
        active_field = key_fields{i_};
        keys.(key_fields{i_}).timer = tic();
      end
      known_key = true;
      break;
    end
  end
  
  if ( key_code(accept_key) )
    current = keys.(active_field);
    if ( isnan(current.timer) || toc(current.timer) > key_debounce_time )
      fprintf( '\n Registered ''%s''.', active_field );
      if ( ~current.was_pressed )
        keys.(active_field).was_pressed = true;
      end
      keys.(active_field).coordinates = tracker.coordinates;
      keys.(active_field).timer = tic();
      if ( ~isempty(tracker.coordinates) )
        brains.util.draw_far_plane_rois( keys, target_size, target_colors, tracker.bypass );
      else
        fprintf( ['\nWARNING: Coordinates not present. Tracking might be deficient;' ...
          , ' you may want to recalibrate.'] );
      end
    end
    known_key = true;
  end
  
  if ( ~known_key )
    key_name = KbName( find(key_code, 1, 'first') );
    fprintf( '\n WARNING: Unregistered key ''%s''.', key_name );
  end
end

%
% cleanup
%

function cleanup()
  ListenChar( 0 );
  
  if ( ~isempty(led_comm) )
    led_comm.close();
  end
  if ( ~isempty(tracker) )
    Eyelink( 'Shutdown' );
  end
end

end

function led_comm = make_led_comm(led_comm_port)

n_leds = 14;

led_comm = brains.arduino.LEDComm( led_comm_port, n_leds );
led_comm.start();

end