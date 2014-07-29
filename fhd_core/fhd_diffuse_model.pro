FUNCTION fhd_diffuse_model,obs,jones,model_filepath=model_filepath,_Extra=extra

dimension=obs.dimension
elements=obs.elements
astr=obs.astr
degpix=obs.degpix
n_pol=obs.n_pol
xy2ad,meshgrid(dimension,elements,1),meshgrid(dimension,elements,2),astr,ra_arr,dec_arr

freq_use=where((*obs.baseline_info).freq_use,nf_use)
f_bin=(*obs.baseline_info).fbin_i
fb_use=Uniq(f_bin[freq_use])
nbin=N_Elements(fb_use)
freq_arr=(*obs.baseline_info).freq
alpha=obs.alpha
freq_norm=freq_arr^(-alpha)
;freq_norm/=Sqrt(Mean(freq_norm^2.))
freq_norm/=Mean(freq_norm) 
d_freq=Median(Float(deriv(freq_arr)))

freq_norm=freq_norm[freq_use[fb_use]]

freq_arr_use=freq_arr[freq_use[fb_use]]/1E6
fb_hist=histogram(f_bin[freq_use],min=0,bin=1)
nf_arr=fb_hist[f_bin[freq_use[fb_use]]]

IF file_test(model_filepath) EQ 0 THEN RETURN,Ptrarr(n_pol)
var_dummy=getvar_savefile(model_filepath,names=var_names)
;save file must have one variable called 'hpx_inds', and at least one other variable. If there are multiple other variables, it must be called 'model_arr'
hpx_inds=getvar_savefile(model_filepath,'hpx_inds')
var_name_inds=where(StrLowCase(var_names) NE 'hpx_inds')
var_names=var_names[var_name_inds]
var_name_use=var_names[(where(StrLowCase(var_names) EQ 'model_arr',n_match))[0]>0] ;will pick 'model_arr' if present, or the first variable that is not 'hpx_inds'
model_hpx_arr=getvar_savefile(model_filepath,var_name_use)

pix2vec_ring,nside,hpx_inds,pix_coords
vec2ang,pix_coords,pix_dec,pix_ra,/astro
ad2xy,pix_ra,pix_dec,astr,xv_hpx,yv_hpx
hpx_i_use=where((xv_hpx GT 0) AND (xv_hpx LT (dimension-1)) AND (yv_hpx GT 0) AND (yv_hpx LT (elements-1)),n_hpx_use) 
IF n_hpx_use EQ 0 THEN RETURN,Ptrarr(n_pol)
xv_hpx=xv_hpx[hpx_i_use]
yv_hpx=yv_hpx[hpx_i_use]

model_stokes_arr=Ptrarr(n_pol)
np_hpx=Total(Ptr_valid(model_hpx_arr))
IF np_hpx EQ 0 THEN BEGIN
    dims=Size(model_hpx_arr,/dimension)
    model_hpx_ptr=Ptr_new(model_hpx_arr)
    model_hpx_arr=Ptrarr(n_pol)
    model_hpx_arr[0]=model_hpx_ptr
    FOR pol_i=1,n_pol-1 DO model_hpx_arr[pol_i]=Ptr_new(Fltarr(dims))
ENDIF ELSE IF np_hpx LT n_pol THEN BEGIN
    dims=Size(*model_hpx_arr[0],/dimension)
    temp_ptr_arr=model_hpx_arr
    model_hpx_arr=Ptrarr(n_pol)
    model_hpx_arr[0:np_hpx-1]=temp_ptr_arr[0:np_hpx-1]
    FOR pol_i=np_hpx,n_pol-1 DO model_hpx_arr[pol_i]=Ptr_new(Fltarr(dims))
ENDIF

x_frac=1.-(xv_hpx-Floor(xv_hpx))
y_frac=1.-(yv_hpx-Floor(yv_hpx))

weights_img=fltarr(dimension,elements)
weights_img[Floor(xv_hpx),Floor(yv_hpx)]+=x_frac*y_frac
weights_img[Floor(xv_hpx),Ceil(yv_hpx)]+=x_frac*(1-y_frac)
weights_img[Ceil(xv_hpx),Floor(yv_hpx)]+=(1-x_frac)*y_frac
weights_img[Ceil(xv_hpx),Ceil(yv_hpx)]+=(1-x_frac)*(1-y_frac)
FOR pol_i=0,n_pol-1 DO BEGIN
    model_img=fltarr(dimension,elements)
    hpx_vals=(*model_hpx_arr[pol_i])[hpx_i_use]
    model_img[Floor(xv_hpx),Floor(yv_hpx)]+=x_frac*y_frac*hpx_vals
    model_img[Floor(xv_hpx),Ceil(yv_hpx)]+=x_frac*(1-y_frac)*hpx_vals
    model_img[Ceil(xv_hpx),Floor(yv_hpx)]+=(1-x_frac)*y_frac*hpx_vals
    model_img[Ceil(xv_hpx),Ceil(yv_hpx)]+=(1-x_frac)*(1-y_frac)*hpx_vals
    model_img*=weight_invert(weights_img)
    model_stokes_arr[pol_i]=Ptr_new(model_img)
ENDFOR

model_arr=Stokes_cnv(model_stokes_arr,jones,_Extra=extra)
Ptr_free,model_stokes_arr
RETURN,model_arr
END