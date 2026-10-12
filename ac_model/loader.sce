// Execute once per Scilab session before examples or Xcos.
AC_ROOT=get_absolute_file_path("loader.sce");
ac_previous_funcprot=funcprot();
funcprot(0);
try
    exec(AC_ROOT+"src/ac_core.sci",-1);
    exec(AC_ROOT+"src/ac_plot.sci",-1);
catch
    ac_load_error=lasterror();
    funcprot(ac_previous_funcprot);
    error(ac_load_error);
end
funcprot(ac_previous_funcprot);
if getos()=="Windows" then
    AC_CP_LIBRARY=AC_ROOT+"lib/CoolProp.dll";
else
    AC_CP_LIBRARY=AC_ROOT+"lib/libCoolProp.so";
end
ac_load_coolprop(AC_CP_LIBRARY);
mprintf("AC model loaded: %s\n",AC_ROOT);
