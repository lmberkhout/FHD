FUNCTION fhd_init,obs,file_path_fhd=file_path_fhd,pol_use=pol_use,freq_use=freq_use,time_i_use=time_i_use,$
    gain_factor=gain_factor,calibration_image_subtract=calibration_image_subtract,$
    max_iter=max_iter,check_iter=check_iter,max_add_sources=max_add_sources,max_sources=max_sources,smooth_width=smooth_width,$
    baseline_threshold=baseline_threshold,beam_threshold=beam_threshold,add_threshold=add_threshold,$
    polarization_map=polarization_map,polarization_correction=polarization_correction,ra_arr=ra_arr,dec_arr=dec_arr,astr=astr,$
    beam_base=beam_base,beam_correction=beam_correction,independent_fit=independent_fit,deconvolution_filter=deconvolution_filter,$
    beam_max_threshold=beam_max_threshold,sigma_cut=sigma_cut,local_max_radius=local_max_radius,$
    reject_pol_sources=reject_pol_sources,filter_background=filter_background,$
    galaxy_model_fit=galaxy_model_fit,transfer_mapfn=transfer_mapfn,joint_deconvolution_list=joint_deconvolution_list


IF N_Elements(obs) EQ 0 THEN BEGIN
    dimension=1024. 
    n_pol=4
ENDIF ELSE BEGIN
    dimension=obs.dimension
    n_pol=obs.n_pol
ENDELSE

IF N_Elements(file_path_fhd) EQ 0 THEN file_path_fhd=''
IF N_Elements(pol_use) EQ 0 THEN pol_use=indgen(n_pol)
IF N_Elements(beam_max_threshold) EQ 0 THEN beam_max_threshold=1e-4 
IF N_Elements(smooth_width) EQ 0 THEN smooth_width=7.
IF N_Elements(local_max_radius) EQ 0 THEN local_max_radius=3.
IF N_Elements(sigma_cut) EQ 0 THEN sigma_cut=2.
;IF N_Elements(baseline_threshold) EQ 0 THEN baseline_threshold=0.;50.
IF N_Elements(beam_threshold) EQ 0 THEN beam_threshold=0.05 ;0.05 is really as far down as you should go with our current beam models!
IF N_Elements(max_sources) EQ 0 THEN max_sources=5000.
IF N_Elements(gain_factor) EQ 0 THEN gain_factor=.15
;IF N_Elements(mapfn_interval) EQ 0 THEN mapfn_interval=0 ;maximum number of iterations before applying the mapping function. 
;IF N_Elements(mapfn_threshold) EQ 0 THEN mapfn_threshold=0.86;(1-gain_factor)*1.01 ;factor of 1.01 is to ensure that a fit to the same component has had the mapping function run first
IF N_Elements(add_threshold) EQ 0 THEN add_threshold=(1.-gain_factor*1.1)>0.5 ;also fit additional components brighter than this threshold
IF N_Elements(max_add_sources) EQ 0 THEN max_add_sources=(Floor(dimension/2./(2.*smooth_width)))^2.
IF N_Elements(max_iter) EQ 0 THEN IF max_add_sources EQ 1 THEN max_iter=max_sources ELSE max_iter=500.
IF N_Elements(check_iter) EQ 0 THEN IF max_add_sources EQ 1 THEN check_iter=Round(5./gain_factor) ELSE check_iter=Round(1./gain_factor)
IF N_Elements(independent_fit) EQ 0 THEN independent_fit=0 ;set to 1 to fit I, Q, (U, V) seperately. Otherwise, only I (and U) is fit
IF N_Elements(reject_pol_sources) EQ 0 THEN reject_pol_sources=0 ;set to exclude source candidates with high Stokes Q/I
IF N_Elements(calibration_image_subtract) EQ 0 THEN calibration_image_subtract=0. ELSE calibration_image_subtract=Float(calibration_image_subtract)
IF N_Elements(transfer_mapfn) EQ 0 THEN transfer_mapfn='False'
IF N_Elements(filter_background) EQ 0 THEN filter_background=1
IF N_Elements(galaxy_model_fit) EQ 0 THEN galaxy_model_fit=0
IF N_Elements(joint_deconvolution_list) LE 1 THEN decon_mode='Single snapshot' ELSE decon_mode='HEALPix integrated'
IF N_Elements(joint_deconvolution_list) EQ 0 THEN joint_obs=file_basename(file_path_fhd) ELSE joint_obs=file_basename(joint_deconvolution_list)
IF N_Elements(deconvolution_filter) EQ 0 THEN deconvolution_filter='filter_uv_natural'

fhd={npol:n_pol,beam_threshold:beam_threshold,max_iter:max_iter,max_sources:max_sources,check_iter:check_iter,$
    gain_factor:gain_factor,add_threshold:add_threshold,max_add_sources:max_add_sources,independent_fit:independent_fit,$
    reject_pol_sources:reject_pol_sources,beam_max_threshold:beam_max_threshold,smooth_width:smooth_width,$
    pol_use:pol_use,sigma_cut:sigma_cut,local_max_radius:local_max_radius,transfer_mapfn:transfer_mapfn,$
    cal_subtract:calibration_image_subtract,galaxy_subtract:galaxy_model_fit,$
    filter_background:filter_background,decon_filter:deconvolution_filter,decon_mode:decon_mode,joint_obs:joint_obs}

RETURN,fhd
END