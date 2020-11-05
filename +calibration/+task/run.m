function run(program)

task = program.Value.task;
states = program.Value.states;

initial_state = states('present_images');
run( task, initial_state );

end