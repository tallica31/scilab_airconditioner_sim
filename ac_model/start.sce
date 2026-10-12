// GUI entry point (Scilab on Windows). Does not install dependencies.
exec(get_absolute_file_path("start.sce")+"run_examples.sce",-1);
exec(AC_ROOT+"build_xcos.sce",-1);
ac_plot_ph(low);
xcos(scs_m);
