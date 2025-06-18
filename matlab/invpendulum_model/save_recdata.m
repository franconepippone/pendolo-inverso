function save_recdata(recdata, path)
    % Saves a recdata struct in the default folder readings/
    % Path may be overwritten by providing the "path" argument
    % If path is not give, data is saved in a file located at readings/
    % and automatically named simrecord<num>, where num is automatically
    % choosen to prevent conflicts with other files

    RECORDS_DIRECTORY = "readings/";
    DEFAULT_RECORDNAME = "simrecord";

    % extract/increment/saves file counter (avoid duplicate files)
    load(RECORDS_DIRECTORY + "counter.mat", "sim_file_counter")
    sim_file_counter = sim_file_counter + 1;
    save(RECORDS_DIRECTORY + "counter.mat", "sim_file_counter");
    
    datastruct.info.og_filename = DEFAULT_RECORDNAME + string(sim_file_counter);
    fullpath = RECORDS_DIRECTORY + datastruct.info.og_filename + ".mat";

    if nargin > 1
        fullpath = path;
    end

    save(fullpath,"recdata");
    disp("Data saved at: " + fullpath)
end