FUNCTION visibility_count,obs,psf,params,flag_ptr=flag_ptr,file_path_fhd=file_path_fhd,no_conjugate=no_conjugate

SWITCH N_Params() OF
    0:obs=getvar_savefile(file_path_fhd+'_obs.sav','obs')
    1:psf=getvar_savefile(file_path_fhd+'_beams.sav','psf')
    2:params=getvar_savefile(file_path_fhd+'_params.sav','params')
    ELSE:
ENDSWITCH


;extract information from the structures
n_pol=obs.n_pol
n_tile=obs.n_tile
n_freq=obs.n_freq
dimension=Float(obs.dimension)
elements=Float(obs.elements)
kbinsize=obs.kpix
kx_span=kbinsize*dimension ;Units are # of wavelengths
ky_span=kx_span
min_baseline=obs.min_baseline
max_baseline=obs.max_baseline
b_info=*obs.baseline_info
freq_cut_i=where(b_info.freq_use,n_freq_cut)

freq_bin_i=b_info.fbin_i
fi_use=where(b_info.freq_use)
freq_bin_i=freq_bin_i[fi_use]

frequency_array=b_info.freq
frequency_array=frequency_array[fi_use]

psf_base=psf.base
psf_dim=Sqrt((Size(*psf_base[0],/dimension))[0])
psf_resolution=(Size(psf_base,/dimension))[2]

kx_arr=params.uu/kbinsize
ky_arr=params.vv/kbinsize
n_frequencies=N_Elements(frequency_array)

xcen=frequency_array#kx_arr
ycen=frequency_array#ky_arr

conj_i=where(ky_arr GT 0,n_conj)
IF n_conj GT 0 THEN BEGIN
    xcen[*,conj_i]=-xcen[*,conj_i]
    ycen[*,conj_i]=-ycen[*,conj_i]
ENDIF

x_offset=Round((Ceil(xcen)-xcen)*psf_resolution) mod psf_resolution    
y_offset=Round((Ceil(ycen)-ycen)*psf_resolution) mod psf_resolution
xmin=Floor(Round(xcen+x_offset/psf_resolution+dimension/2.)-psf_dim/2.) 
ymin=Floor(Round(ycen+y_offset/psf_resolution+elements/2.)-psf_dim/2.) 
xmax=xmin+psf_dim-1
ymax=ymin+psf_dim-1

range_test_x_i=where((xmin LE 0) OR (xmax GE dimension-1),n_test_x)
range_test_y_i=where((ymin LE 0) OR (ymax GE elements-1),n_test_y)
xmax=(ymax=0)
IF n_test_x GT 0 THEN xmin[range_test_x_i]=(ymin[range_test_x_i]=-1)
IF n_test_y GT 0 THEN xmin[range_test_y_i]=(ymin[range_test_y_i]=-1)

dist_test=Sqrt((xcen)^2.+(ycen)^2.)*kbinsize
flag_dist_i=where((dist_test LT min_baseline) OR (dist_test GT max_baseline),n_dist_flag)
IF n_dist_flag GT 0 THEN BEGIN
    xmin[flag_dist_i]=-1
    ymin[flag_dist_i]=-1
ENDIF

IF Keyword_Set(flag_ptr) THEN BEGIN
    n_flag_dim=size(*flag_ptr[0],/n_dimension)
    flag_i=where(*flag_ptr[0] LE 0,n_flag,ncomplement=n_unflag)
    IF n_flag GT 0 THEN BEGIN
        xmin[flag_i]=-1
        ymin[flag_i]=-1
    ENDIF
ENDIF

;match all visibilities that map from and to exactly the same pixels
bin_n=histogram(xmin+ymin*dimension,binsize=1,reverse_indices=ri,min=0) ;should miss any (xmin,ymin)=(-1,-1) from flags
bin_i=where(bin_n,n_bin_use)

weights=fltarr(dimension,elements)
FOR bi=0L,n_bin_use-1 DO BEGIN
    inds=ri[ri[bin_i[bi]]:ri[bin_i[bi]+1]-1]
    ind0=inds[0]
    
    xmin_use=xmin[ind0] ;should all be the same, but don't want an array
    ymin_use=ymin[ind0]
    weights[xmin_use:xmin_use+psf_dim-1,ymin_use:ymin_use+psf_dim-1]+=bin_n[bin_i[bi]]
ENDFOR
    
IF ~Keyword_Set(no_conjugate) THEN BEGIN
    weights_mirror=Shift(Reverse(reverse(weights,1),2),1,1)
    weights=(weights+weights_mirror)/2.
ENDIF
RETURN,weights
END