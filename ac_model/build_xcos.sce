// Creates an editable steady-state Xcos diagram. Run loader.sce first.
if exists("ac_cycle")==0 then error("Run loader.sce first."); end
loadXcosLibs(); loadScicos();
scs_m=scicos_diagram();
scs_m.props.title="R1234yf steady parallel cycle";
scs_m.props.tf=1;
scs_m.props.context=["// Run loader.sce before simulation."; ..
    "// Input: [Te_C;Tc_C;SH_e_K;SH_ch_K;SC_K;eta;mode;a;b]"; ..
    "// mode 1: a,b in kg/h; 2: a,b in kW; 3: a in kW,b in kg/h"; ..
    "// Simulation time is only a sampling axis; no physical dynamics."];

u=[5;50;5;5;5;0.7;1;150;100];
b1=CONST_m("define");
b1.model.sim=list("cstblk4_m",4); b1.model.rpar=[]; b1.model.opar=list(u);
b1.model.out=9; b1.model.out2=1; b1.model.outtyp=1;
b1.graphics.exprs=sci2exp(u); b1.graphics.orig=[40,160]; b1.graphics.sz=[70,50];
b1.graphics.id="Conditions / mode / demands"; b1.graphics.pout=5;

b2=scifunc_block_m("define");
b2.model.in=9; b2.model.in2=1; b2.model.out=12; b2.model.out2=1;
codes=list("y1=ac_xcos_eval(u1)"," "," ","y1=ac_xcos_eval(u1)"," "," "," ");
b2.model.opar=codes;
b2.graphics.exprs=list(["[9,1]";"[12,1]";"[]";"[]";"[]";"[]";"[]";"[]";"0"],codes);
b2.graphics.orig=[190,160]; b2.graphics.sz=[90,50];
b2.graphics.id="Steady cycle"; b2.graphics.pin=5; b2.graphics.pout=6;

b3=TOWS_c("define");
varname="AC_LOG";
b3.model.in=12; b3.model.in2=1; b3.model.intyp=1;
b3.model.ipar=[128;length(varname);ascii(varname)'];
b3.graphics.exprs=["128";varname;"0"];
b3.graphics.orig=[370,160]; b3.graphics.sz=[80,50];
b3.graphics.id="AC_LOG (12 outputs)"; b3.graphics.pin=6; b3.graphics.pein=7;

b4=CLOCK_c("define");
b4.graphics.orig=[380,280]; b4.graphics.sz=[50,35]; b4.graphics.peout=7;

scs_m.objs(1)=b1; scs_m.objs(2)=b2; scs_m.objs(3)=b3; scs_m.objs(4)=b4;
lk=scicos_link(); lk.xx=[110;190]; lk.yy=[185;185];
lk.ct=[1,1]; lk.from=[1,1,0]; lk.to=[2,1,1]; scs_m.objs(5)=lk;
lk=scicos_link(); lk.xx=[280;370]; lk.yy=[185;185];
lk.ct=[1,1]; lk.from=[2,1,0]; lk.to=[3,1,1]; scs_m.objs(6)=lk;
lk=scicos_link(); lk.xx=[405;410;410]; lk.yy=[280;250;210];
lk.ct=[5,-1]; lk.from=[4,1,0]; lk.to=[3,1,1]; scs_m.objs(7)=lk;
mprintf("Diagram created in scs_m. Run xcos(scs_m) to open it.\n");
mprintf("Save as ac_steady.zcos in Xcos. Run loader.sce before reopening/simulating.\n");
