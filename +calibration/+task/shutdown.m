function shutdown(program)

attempt( @() stop(program.Value.calibration_manager) );
set_input_listen_state();

end

function set_input_listen_state()

ShowCursor();
ListenChar( 0 );

end


function attempt(func)

try
  func()
catch err
  warning( err.message );
end

end