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
  trigger( reward_manager, reward_size );
  reset( key_timer );
end

update( ni_scan_output );
update( reward_manager );

end