{
    # run with: cat ../../../board_files/TE080x_board_files.csv| grep -Ev '#|CSV_VERSION|SHORTNAME' | awk -F ',' -f create_symlinks.awk
    # Ignore the 'File Exists' lines
    if ($1 < 1000)
        destination="sw_lib_te0803";
    else if ($1 > 1999)
        destination="sw_lib_te0808";
    else
        destination="sw_lib_te0807";

    #print $5, destination;
    system("echo ln -svFT "destination " " $5);
    system("ln -svFT "destination " " $5);
}
