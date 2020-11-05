classdef EyelinkCalibration < handle
  properties
    StartSetupTimeout = 5;
    NumCalibrationPoints = 5;
    CalibrationRect = ptb.Rect.Configured( ...
      'IsNonNan', true ...
      , 'IsNonNegative', true ...
      , 'IsInteger', true ...
    );
  end
  
  properties (Access = private)
    is_initialized = false;
    is_in_calibration_mode = false;
  end
  
  methods
    function obj = EyelinkCalibration(calibration_rect)
      obj.CalibrationRect = calibration_rect;
    end
    
    function set.CalibrationRect(obj, to)
      obj.CalibrationRect = set( obj.CalibrationRect, to );
    end
    
    function set.NumCalibrationPoints(obj, to)
      validateattributes( to, {'double'}, {'scalar', 'nonnan', 'positive', 'finite'} ...
        , 'NumCalibrationPoints', mfilename );
      obj.NumCalibrationPoints = to;
    end
    
    function delete(obj)
      stop( obj );
    end
    
    function stop(obj)
      if ( obj.is_initialized )
        try
          Eyelink( 'Shutdown' );
        catch err
          warning( 'Failed to shutdown eyelink; message: %s', err.message );
        end
      end
      
      obj.is_initialized = false;
      obj.is_in_calibration_mode = false;
    end
    
    function accept_fixation(obj)
      Eyelink( 'command', 'accept_target_fixation' );
    end
    
    function start(obj)
      result = EyelinkInit();
      if ( ~result )
        error( 'Failed to initialize Eyelink connection.' );
      end
      
      obj.is_initialized = true;
      
      coords_inputs = make_screen_pixel_coords_command_inputs( obj );
      calibration_type_inputs = make_calibration_type_command_inputs( obj );
      
      status = Eyelink( 'Command', coords_inputs{:} );
      if ( status ~= 0 )
        stop( obj );
        error( 'Failed to send screen pixel coordinates; coordinates were: [%d %d %d %d].' ...
          , coords_inputs{2:end} );
      end
      
      status = Eyelink( 'Command', calibration_type_inputs{:} );
      if ( status ~= 0 )
        stop( obj );
        error( 'Failed to send calibration type; was: %s.', calibration_type_inputs{1} );
      end
      
      status = Eyelink( 'StartSetup' );
      if ( status ~= 0 )
        stop( obj );
        error( 'Failed to start setup.' );
      end
      
      cont = true;
      timer = ptb.Clock();
      
      while ( cont && Eyelink( 'CurrentMode' ) ~= 2 )
        if ( elapsed(timer) > obj.StartSetupTimeout )
          stop( obj );
          error( 'Failed to enter calibration mode within %0.2f seconds.' ...
            , obj.StartSetupTimeout );
        end
      end
      
      Eyelink( 'SendKeyButton', double('c'), 0, 10 );
      obj.is_in_calibration_mode = true;
    end
  end
  
  methods (Access = private)
    function command_inputs = make_calibration_type_command_inputs(obj)
      calibration_type_str = sprintf( 'calibration_type = HV%d' ...
        , obj.NumCalibrationPoints );
      command_inputs = { calibration_type_str };
    end
    
    function command_inputs = make_screen_pixel_coords_command_inputs(obj)
      pixel_coords_command_str = 'screen_pixel_coords = %d %d %d %d';
      rect = get( obj.CalibrationRect );
      
      command_inputs = { pixel_coords_command_str };
      
      for i = 1:4
        command_inputs{end+1} = rect(i);
      end 
    end
  end
end