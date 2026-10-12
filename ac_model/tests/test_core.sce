// Meaningful numerical and invalid-input regression tests; run after loader.sce.
function check_near(actual,expected,tol,label)
    if max(abs(actual-expected))>tol then error("FAIL: "+label); end
endfunction
function check_error(c,label)
    ierr=execstr("ac_cycle(c);","errcatch");
    if ierr==0 then error("Expected error: "+label); end
endfunction
c=ac_defaults(); lo=ac_cycle(c);
check_near(lo.summary(1:2),[0.373;1.302],0.002,"reference pressures MPaA");
check_near(lo.summary(6:9),[4.54;3.03;2.26;9.84],0.025,"PDF low heat rates kW");
check_near(lo.summary(11),0.35,0.015,"reference inlet quality");
if abs(lo.energy_residual_W)>1e-7 then error("Low energy balance"); end
if abs(lo.mass_residual_kgs)>1e-14 then error("Low mass balance"); end
c.value_ch=250; hi=ac_cycle(c);
check_near(hi.summary(5),400,1e-9,"high total kg/h");
check_near(hi.summary(6:9),[4.54;7.57;3.62;15.74],0.025,"PDF high heat rates kW");

// Forward -> inverse must recover both original branch flows.
c=ac_defaults(); c.mode_e="capacity"; c.mode_ch="capacity";
c.value_e=lo.summary(6); c.value_ch=lo.summary(7); inv=ac_cycle(c);
check_near(inv.summary,lo.summary,1e-8,"forward/inverse round trip");
c=ac_defaults(); c.mode_e="capacity"; c.value_e=5; mixed=ac_cycle(c);
check_near(mixed.summary(6),5,1e-10,"mixed capacity");
check_near(mixed.summary(4),100,1e-10,"mixed fixed chiller flow");

// Unequal superheats exercise enthalpy mixing; zero-flow branch must not affect suction.
c=ac_defaults(); c.SH_ch_K=15; r=ac_cycle(c);
hMix=(150*r.states(8).h_Jkg+100*r.states(12).h_Jkg)/250;
check_near(r.states(1).h_Jkg,hMix,1e-7,"mixing enthalpy");
c.value_ch=0; r=ac_cycle(c);
check_near(r.states(1).h_Jkg,r.states(8).h_Jkg,1e-7,"inactive branch mixing");
check_near(r.summary(7),0,1e-10,"inactive branch capacity");

// Saturated endpoints must avoid ambiguous P,T property calls.
c=ac_defaults(); c.SH_e_K=0; c.SH_ch_K=0; c.SC_K=0; r=ac_cycle(c);
check_near(r.states(1).quality,1,1e-8,"saturated suction");
check_near(r.states(4).quality,0,1e-8,"saturated liquid");
c=ac_defaults(); c.Tc_C=55; r=ac_cycle(c);
if r.summary(2)<=lo.summary(2) | r.summary(7)>=lo.summary(7) then
    error("Condensing temperature sensitivity");
end
c=ac_defaults(); c.value_e=0; c.value_ch=0; check_error(c,"zero total flow");
c=ac_defaults(); c.eta_is=0; check_error(c,"zero efficiency");
c=ac_defaults(); c.eta_is=1.1; check_error(c,"efficiency above one");
c=ac_defaults(); c.value_ch=-1; check_error(c,"negative demand");
c=ac_defaults(); c.Te_C=60; check_error(c,"reversed temperatures");
c=ac_defaults(); c.Tc_C=100; check_error(c,"supercritical condenser");
c=ac_defaults(); c.SH_e_K=%nan; check_error(c,"NaN");
c=ac_defaults(); c.mode_e="unknown"; check_error(c,"unknown mode");
check_near(ac_xcos_eval([5;50;5;5;5;0.7;1;150;100]),lo.summary,1e-8,"Xcos adapter");
mprintf("PASS: core reference, balances, inverse, mixing, saturation, sensitivity and invalid inputs.\n");
