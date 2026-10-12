exec(get_absolute_file_path("run_sweep.sce")+"loader.sce",-1);
c=ac_defaults(); c.value_ch=250;
rows="Tc_C,"+strcat(ac_summary_names()' ,",");
for Tc=40:5:65
    c.Tc_C=Tc; r=ac_cycle(c);
    row=msprintf("%.10g",Tc);
    for k=1:12, row=row+msprintf(",%.10g",r.summary(k)); end
    rows($+1)=row;
end
if ~isdir(AC_ROOT+"results") then mkdir(AC_ROOT+"results"); end
mputl(rows,AC_ROOT+"results/condensing_temperature_sweep.csv");
disp(rows);
// Tc is prescribed. This is NOT a prediction from outside-air temperature.
