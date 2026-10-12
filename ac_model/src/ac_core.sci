// Steady R1234yf parallel evaporator/chiller cycle. SI units internally.
function v = ac_props(out, in1, v1, in2, v2)
    v = call("propssi_", out,1,"c", in1,2,"c", double(v1),3,"d", ..
             in2,4,"c", double(v2),5,"d", "R1234yf",6,"c", ..
             "out",[1,1],7,"d");
    if isnan(v) | isinf(v) then
        error(msprintf("CoolProp failed: %s(%s=%.12g, %s=%.12g)",out,in1,v1,in2,v2));
    end
endfunction

function ac_load_coolprop(path)
    global AC_CP_LOADED_PATH;
    if c_link("propssi_") then
        if isempty(AC_CP_LOADED_PATH) then
            error("propssi_ is already linked outside this package. Restart Scilab, then run loader.sce.");
        end
        if AC_CP_LOADED_PATH <> path then
            error("A different CoolProp library is loaded. Restart Scilab before changing it.");
        end
    else
        if ~isfile(path) then
            error("CoolProp library not found: "+path+". See README_JA.md.");
        end
        link(path,"propssi_","c");
        AC_CP_LOADED_PATH = path;
    end
    p = ac_props("P","T",278.15,"Q",1);
    if abs(p/1e6-0.373) > 0.01 then
        error("CoolProp R1234yf connection check failed.");
    end
endfunction

function c = ac_defaults()
    c = struct("Te_C",5,"Tc_C",50,"SH_e_K",5,"SH_ch_K",5, ..
        "SC_K",5,"eta_is",0.70,"mode_e","flow","mode_ch","flow", ..
        "value_e",150,"value_ch",100);
endfunction

function ac_scalar(v, name)
    if type(v) <> 1 then error(name+" must be a real scalar."); end
    if size(v,"*") <> 1 then error(name+" must be a scalar."); end
    if ~isreal(v) then error(name+" must be real."); end
    if isnan(v) | isinf(v) then error(name+" must be finite."); end
endfunction

function ac_validate(c)
    names = ["Te_C";"Tc_C";"SH_e_K";"SH_ch_K";"SC_K";"eta_is";"value_e";"value_ch"];
    for k=1:size(names,"*")
        if ~isfield(c,names(k)) then error("Missing parameter: "+names(k)); end
        ac_scalar(c(names(k)),names(k));
    end
    if c.Tc_C <= c.Te_C then error("Tc_C must be greater than Te_C."); end
    if min([c.SH_e_K,c.SH_ch_K,c.SC_K,c.value_e,c.value_ch]) < 0 then
        error("Superheat, subcooling and branch demands must be nonnegative.");
    end
    if c.eta_is <= 0 | c.eta_is > 1 then error("eta_is must satisfy 0 < eta_is <= 1."); end
    for name=["mode_e","mode_ch"]
        if ~isfield(c,name) then error("Missing parameter: "+name); end
        m=c(name);
        if type(m)<>10 then error(name+" must be flow or capacity."); end
        if size(m,"*")<>1 then error(name+" must be scalar."); end
        if m<>"flow" & m<>"capacity" then error(name+" must be flow or capacity."); end
    end
endfunction

function s = ac_state(p,h)
    hf=ac_props("H","P",p,"Q",0);
    hg=ac_props("H","P",p,"Q",1);
    q=(h-hf)/(hg-hf);
    tol=1e-7;
    if q < -tol then
        phase="subcooled_liquid"; q=%nan;
    elseif q > 1+tol then
        phase="superheated_vapor"; q=%nan;
    elseif abs(q)<tol then
        phase="saturated_liquid"; q=0;
    elseif abs(q-1)<tol then
        phase="saturated_vapor"; q=1;
    else
        phase="two_phase";
    end
    s=struct("p_Pa",p,"h_Jkg",h,"T_C",ac_props("T","P",p,"H",h)-273.15, ..
        "rho_kgm3",ac_props("D","P",p,"H",h),"quality",q,"phase",phase);
endfunction

function h = ac_vapor_out(p,Te_C,SH_K)
    if SH_K==0 then
        h=ac_props("H","P",p,"Q",1);
    else
        h=ac_props("H","P",p,"T",Te_C+273.15+SH_K);
    end
endfunction

function m = ac_branch_flow(mode,value,dh)
    if dh<=0 then error("Evaporator enthalpy rise must be positive."); end
    if mode=="flow" then m=value/3600; else m=value*1000/dh; end
endfunction

function r = ac_cycle(c)
    ac_validate(c);
    Tmin=ac_props("Ttriple","",0,"",0)-273.15;
    Tmax=ac_props("Tcrit","",0,"",0)-273.15;
    if c.Te_C<=Tmin | c.Tc_C>=Tmax | c.Tc_C-c.SC_K<=Tmin then
        error("This subcritical model requires temperatures strictly between triple and critical limits.");
    end
    pL=ac_props("P","T",c.Te_C+273.15,"Q",1);
    pH=ac_props("P","T",c.Tc_C+273.15,"Q",0);
    if c.SC_K==0 then
        h3=ac_props("H","P",pH,"Q",0);
    else
        h3=ac_props("H","P",pH,"T",c.Tc_C+273.15-c.SC_K);
    end
    h4=h3;
    hE=ac_vapor_out(pL,c.Te_C,c.SH_e_K);
    hC=ac_vapor_out(pL,c.Te_C,c.SH_ch_K);
    mE=ac_branch_flow(c.mode_e,c.value_e,hE-h4);
    mC=ac_branch_flow(c.mode_ch,c.value_ch,hC-h4);
    m=mE+mC;
    if m<=0 then error("At least one branch must have positive flow or capacity."); end
    h1=(mE*hE+mC*hC)/m;
    s1=ac_props("S","P",pL,"H",h1);
    h2s=ac_props("H","P",pH,"S",s1);
    h2=h1+(h2s-h1)/c.eta_is;
    if h2<h1 then error("Negative compressor enthalpy rise."); end
    Qe=mE*(hE-h4); Qch=mC*(hC-h4);
    W=m*(h2-h1); Qcond=m*(h2-h3);
    energyResidual=Qcond-Qe-Qch-W;
    if abs(energyResidual)>1e-8*max([1,Qcond]) then error("Energy balance failed."); end
    labels=["compressor_in";"compressor_out";"condenser_in";"condenser_out"; ..
        "evap_valve_in";"evap_valve_out";"evaporator_in";"evaporator_out"; ..
        "chiller_valve_in";"chiller_valve_out";"chiller_in";"chiller_out"];
    p=[pL;pH;pH;pH;pH;pL;pL;pL;pH;pL;pL;pL];
    h=[h1;h2;h2;h3;h3;h4;h4;hE;h3;h4;h4;hC];
    flows=[m;m;m;m;mE;mE;mE;mE;mC;mC;mC;mC];
    states=list();
    for k=1:12
        st=ac_state(p(k),h(k));
        st.name=labels(k); st.m_kgs=flows(k); st.active=(flows(k)>0);
        states(k)=st;
    end
    if states(6).phase<>"two_phase" & states(6).phase<>"saturated_liquid" then
        error("Valve outlet is outside the supported liquid/two-phase inlet range. Revise Te/Tc/SC.");
    end
    summary=[pL/1e6;pH/1e6;mE*3600;mC*3600;m*3600;Qe/1000;Qch/1000; ..
        W/1000;Qcond/1000;states(2).T_C;states(6).quality;(Qe+Qch)/W];
    r=struct("config",c,"states",states,"summary",summary, ..
        "energy_residual_W",energyResidual,"mass_residual_kgs",m-mE-mC, ..
        "dh_e_Jkg",hE-h4,"dh_ch_Jkg",hC-h4);
endfunction

function names=ac_summary_names()
    names=["p_low_MPaA";"p_high_MPaA";"m_evap_kgh";"m_chiller_kgh";"m_total_kgh"; ..
        "Q_evap_kW";"Q_chiller_kW";"W_to_refrigerant_kW";"Q_condenser_kW"; ..
        "T_discharge_C";"quality_valve_out";"COP_refrigerant"];
endfunction

function ac_report(r)
    mprintf("\nR1234yf steady cycle -- prescribed Te/Tc/SH/SC\n");
    names=ac_summary_names();
    for k=1:12, mprintf("%-25s %12.6f\n",names(k),r.summary(k)); end
    mprintf("Energy residual [W]: %.3e\n",r.energy_residual_W);
    mprintf("\n%-22s %9s %10s %11s %9s %10s %s\n", ..
        "Port","T[C]","p[MPaA]","h[kJ/kg]","m[kg/h]","quality","phase");
    for k=1:length(r.states)
        s=r.states(k); q="--";
        if ~isnan(s.quality) then q=msprintf("%.5f",s.quality); end
        suffix=""; if ~s.active then suffix=" (inactive; nominal state)"; end
        mprintf("%-22s %9.3f %10.6f %11.4f %9.3f %10s %s%s\n", ..
            s.name,s.T_C,s.p_Pa/1e6,s.h_Jkg/1000,s.m_kgs*3600,q,s.phase,suffix);
    end
endfunction

function ac_export(r,folder,stem)
    if ~isdir(folder) then mkdir(folder); end
    rows="port,T_C,p_MPaA,h_kJkg,rho_kgm3,m_kgh,quality,phase,active";
    for k=1:length(r.states)
        s=r.states(k); q="";
        if ~isnan(s.quality) then q=msprintf("%.10g",s.quality); end
        rows($+1)=msprintf("%s,%.10g,%.10g,%.10g,%.10g,%.10g,%s,%s,%d", ..
            s.name,s.T_C,s.p_Pa/1e6,s.h_Jkg/1000,s.rho_kgm3,s.m_kgs*3600,q,s.phase,bool2s(s.active));
    end
    mputl(rows,folder+filesep()+stem+"_states.csv");
    names=ac_summary_names(); rows="metric,value";
    for k=1:12, rows($+1)=msprintf("%s,%.12g",names(k),r.summary(k)); end
    rows($+1)=msprintf("energy_residual_W,%.12g",r.energy_residual_W);
    rows($+1)=msprintf("mass_residual_kgs,%.12g",r.mass_residual_kgs);
    mputl(rows,folder+filesep()+stem+"_summary.csv");
    c=r.config;
    rows=["parameter,value";"fluid,R1234yf";"mode_e,"+c.mode_e;"mode_ch,"+c.mode_ch];
    for name=["Te_C","Tc_C","SH_e_K","SH_ch_K","SC_K","eta_is","value_e","value_ch"]
        rows($+1)=msprintf("%s,%.12g",name,c(name));
    end
    mputl(rows,folder+filesep()+stem+"_inputs.csv");
endfunction

function y=ac_xcos_eval(u)
    if size(u,"*")<>9 then error("Xcos input must contain 9 values."); end
    c=ac_defaults();
    c.Te_C=u(1); c.Tc_C=u(2); c.SH_e_K=u(3); c.SH_ch_K=u(4);
    c.SC_K=u(5); c.eta_is=u(6); c.value_e=u(8); c.value_ch=u(9);
    select u(7)
    case 1 then c.mode_e="flow"; c.mode_ch="flow";
    case 2 then c.mode_e="capacity"; c.mode_ch="capacity";
    case 3 then c.mode_e="capacity"; c.mode_ch="flow";
    else error("Mode must be 1=flow, 2=capacity, or 3=mixed.");
    end
    r=ac_cycle(c); y=r.summary;
endfunction
