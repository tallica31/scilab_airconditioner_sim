exec(get_absolute_file_path("selftest.sce")+"loader.sce",-1);
exec(AC_ROOT+"tests/test_core.sce",-1);
exec(AC_ROOT+"build_xcos.sce",-1);
scicos_simulate(scs_m,list(),struct(),"nw");
expected=ac_xcos_eval([5;50;5;5;5;0.7;1;150;100]);
if size(AC_LOG.values,2)<>12 | size(AC_LOG.values,1)<1 then
    error("FAIL: Xcos output shape.");
end
for k=1:size(AC_LOG.values,1)
    check_near(AC_LOG.values(k,:)',expected,1e-8,"Xcos integrated output");
end
for mode=[2,3]
    u=[5;50;5;5;5;0.7;mode;5;3];
    if mode==3 then u(9)=100; end
    scs_m.objs(1).model.opar=list(u);
    scs_m.objs(1).graphics.exprs=sci2exp(u);
    scicos_simulate(scs_m,list(),struct(),"nw");
    if size(AC_LOG.values,1)<1 then error("FAIL: no Xcos samples."); end
    check_near(AC_LOG.values($,6),5,1e-8,"Xcos prescribed cabin capacity");
    if mode==2 then
        check_near(AC_LOG.values($,7),3,1e-8,"Xcos inverse chiller capacity");
    else
        check_near(AC_LOG.values($,4),100,1e-8,"Xcos mixed chiller flow");
    end
end
mprintf("PASS: integrated Xcos simulation and all output samples.\n");
