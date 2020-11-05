function state = present_images(program)

state = ptb.State();
state.Duration = 1;
state.Name = 'present_images';
state.UserData = struct();
state.UserData.need_update_target_location = true;
state.UserData.marked_key_press = false;

state.Entry = @(state) entry( state, program );
state.Exit = @(state) exit( state, program );
state.Loop = @(state) loop( state, program );

end

function entry(state, program)

maybe_update_target_locations( state, program );

window = program.Value.main_window;
stimuli = program.Value.stimuli;

if ( isempty(stimuli) )
  flip( window );
  return
end

stimulus_ind = randi( numel(stimuli), 1 );
stimulus = stimuli{stimulus_ind};

stimulus.Position.Units = 'px';
stimulus.Position = state.UserData.target_location;

draw( stimulus, window );
flip( window );

end

function loop(state, program)

if ( ptb.util.is_key_down(ptb.keys.space()) && ~state.UserData.marked_key_press )
  state.UserData.marked_key_press = true;
  state.UserData.need_update_target_location = true;
  accept_fixation( program.Value.calibration_manager );
  escape( state );
end

end

function exit(state, program)

next( state, program.Value.states('present_images') );

end

function maybe_update_target_locations(state, program)

if ( state.UserData.need_update_target_location )  
  [~, targ_x, targ_y] = Eyelink( 'TargetCheck' );
  state.UserData.target_location = [ targ_x, targ_y ];
  state.UserData.marked_key_press = false;
end

end