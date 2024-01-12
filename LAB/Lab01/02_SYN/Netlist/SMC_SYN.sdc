###################################################################

# Created by write_sdc on Sun Nov  5 23:55:08 2023

###################################################################
set sdc_version 2.1

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA
set_operating_conditions -max slow -max_library slow\
                         -min fast -min_library fast
set_wire_load_mode top
set_wire_load_model -name umc18_wl10 -library slow
set_load -pin_load 0.05 [get_ports {out_n[7]}]
set_load -pin_load 0.05 [get_ports {out_n[6]}]
set_load -pin_load 0.05 [get_ports {out_n[5]}]
set_load -pin_load 0.05 [get_ports {out_n[4]}]
set_load -pin_load 0.05 [get_ports {out_n[3]}]
set_load -pin_load 0.05 [get_ports {out_n[2]}]
set_load -pin_load 0.05 [get_ports {out_n[1]}]
set_load -pin_load 0.05 [get_ports {out_n[0]}]
set_max_delay 20  -from [list [get_ports {mode[1]}] [get_ports {mode[0]}] [get_ports {W_0[2]}]  \
[get_ports {W_0[1]}] [get_ports {W_0[0]}] [get_ports {V_GS_0[2]}] [get_ports   \
{V_GS_0[1]}] [get_ports {V_GS_0[0]}] [get_ports {V_DS_0[2]}] [get_ports        \
{V_DS_0[1]}] [get_ports {V_DS_0[0]}] [get_ports {W_1[2]}] [get_ports {W_1[1]}] \
[get_ports {W_1[0]}] [get_ports {V_GS_1[2]}] [get_ports {V_GS_1[1]}]           \
[get_ports {V_GS_1[0]}] [get_ports {V_DS_1[2]}] [get_ports {V_DS_1[1]}]        \
[get_ports {V_DS_1[0]}] [get_ports {W_2[2]}] [get_ports {W_2[1]}] [get_ports   \
{W_2[0]}] [get_ports {V_GS_2[2]}] [get_ports {V_GS_2[1]}] [get_ports           \
{V_GS_2[0]}] [get_ports {V_DS_2[2]}] [get_ports {V_DS_2[1]}] [get_ports        \
{V_DS_2[0]}] [get_ports {W_3[2]}] [get_ports {W_3[1]}] [get_ports {W_3[0]}]    \
[get_ports {V_GS_3[2]}] [get_ports {V_GS_3[1]}] [get_ports {V_GS_3[0]}]        \
[get_ports {V_DS_3[2]}] [get_ports {V_DS_3[1]}] [get_ports {V_DS_3[0]}]        \
[get_ports {W_4[2]}] [get_ports {W_4[1]}] [get_ports {W_4[0]}] [get_ports      \
{V_GS_4[2]}] [get_ports {V_GS_4[1]}] [get_ports {V_GS_4[0]}] [get_ports        \
{V_DS_4[2]}] [get_ports {V_DS_4[1]}] [get_ports {V_DS_4[0]}] [get_ports        \
{W_5[2]}] [get_ports {W_5[1]}] [get_ports {W_5[0]}] [get_ports {V_GS_5[2]}]    \
[get_ports {V_GS_5[1]}] [get_ports {V_GS_5[0]}] [get_ports {V_DS_5[2]}]        \
[get_ports {V_DS_5[1]}] [get_ports {V_DS_5[0]}]]  -to [list [get_ports {out_n[7]}] [get_ports {out_n[6]}] [get_ports            \
{out_n[5]}] [get_ports {out_n[4]}] [get_ports {out_n[3]}] [get_ports           \
{out_n[2]}] [get_ports {out_n[1]}] [get_ports {out_n[0]}]]
