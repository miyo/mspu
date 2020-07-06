
quartus_map --read_settings_files=on --write_settings_files=off core_de0cv -c core_de0cv
quartus_fit --read_settings_files=off --write_settings_files=off core_de0cv -c core_de0cv
quartus_asm --read_settings_files=off --write_settings_files=off core_de0cv -c core_de0cv
quartus_sta core_de0cv -c core_de0cv
quartus_eda --read_settings_files=off --write_settings_files=off core_de0cv -c core_de0cv

