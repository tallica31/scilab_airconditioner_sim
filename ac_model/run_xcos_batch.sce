exec(get_absolute_file_path("run_xcos_batch.sce")+"loader.sce",-1);
exec(AC_ROOT+"build_xcos.sce",-1);
scicos_simulate(scs_m,list(),struct(),"nw");
mprintf("Columns in AC_LOG.values:\n"); disp(ac_summary_names());
disp(AC_LOG);
