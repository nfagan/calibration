function start(varargin)

program = calibration.task.setup( varargin{:} );
err = [];

try
  calibration.task.run( program );
catch err
end

delete( program );

if ( ~isempty(err) )
  rethrow( err );
end

end