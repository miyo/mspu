
quartus_map --read_settings_files=on --write_settings_files=off core_de10lite -c core_de10lite
quartus_fit --read_settings_files=off --write_settings_files=off core_de10lite -c core_de10lite
quartus_asm --read_settings_files=off --write_settings_files=off core_de10lite -c core_de10lite
#quartus_sta core_de10lite -c core_de10lite
quartus_eda --read_settings_files=off --write_settings_files=off core_de10lite -c core_de10lite

