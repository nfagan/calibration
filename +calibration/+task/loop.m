function loop(task, program)

if ( Eyelink('CurrentMode') ~= 10 )
  escape( task );
end

ni_scan_output = program.Value.ni_scan_output;
reward_manager = program.Value.reward_manager;
reward_size = program.Value.reward_info.reward_size;
key_timer = program.Value.reward_info.key_timer;
key_timeout = program.Value.reward_info.key_timeout;

if ( elapsed(key_timer) > key_timeout && ptb.util.is_key_down(ptb.keys.r) )
  if ( ~isempty(ni_scan_output) )
    trigger( reward_manager, reward_size );
  else
    reward( reward_manager, 1, reward_size * 1e3 ); % ms for arduino reward manager.
  end
  
  reset( key_timer );
end

if ( ~isempty(ni_scan_output) )
  update( ni_scan_output );
end

update( reward_manager );

end