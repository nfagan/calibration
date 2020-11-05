%%

display_opts = struct();
display_opts.index = 4;
display_opts.rect = [];
display_opts.skip_sync_tests = true;

calibration_rect = [0, 0, 1280, 1024];

stimulus_info = struct();
stimulus_info.size = 0.1;
stimulus_info.units = 'normalized';

reward_info = struct();
reward_info.channel_index = 1;
reward_info.reward_size = 0.1;

calibration.task.start( display_opts, calibration_rect, stimulus_info, reward_info );