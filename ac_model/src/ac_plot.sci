function ac_plot_ph(r)
    // State connections are schematic. No spatial heat-exchanger profile.
    T=linspace(-30,ac_props("Tcrit","",0,"",0)-273.15-0.1,160);
    hf=zeros(T); hg=zeros(T); p=zeros(T);
    for k=1:size(T,"*")
        p(k)=ac_props("P","T",T(k)+273.15,"Q",0)/1e6;
        hf(k)=ac_props("H","T",T(k)+273.15,"Q",0)/1000;
        hg(k)=ac_props("H","T",T(k)+273.15,"Q",1)/1000;
    end
    scf(); clf(); plot(hf,p,"k-",hg,p,"k-");
    a=gca(); a.auto_clear="off"; a.log_flags="nl";
    for ids=list([1,2,4,6,8,1],[4,10,12,1])
        xx=[]; yy=[];
        for j=ids, xx($+1)=r.states(j).h_Jkg/1000; yy($+1)=r.states(j).p_Pa/1e6; end
        plot(xx,yy,"-o");
    end
    xtitle("R1234yf p-h: state connections (schematic)","Specific enthalpy [kJ/kg]","Absolute pressure [MPaA]");
    xgrid();
endfunction
