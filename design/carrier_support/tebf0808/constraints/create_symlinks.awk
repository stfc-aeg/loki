{
    if ($1 < 1000)
        destination="te0803_generic";
    else if ($1 > 1999)
        destination="te0808_generic";
    else
        destination="te0807_generic";

    #print $5, destination;
    system("echo ln -svFT "destination " " $5);
    system("ln -svFT "destination " " $5);
}
