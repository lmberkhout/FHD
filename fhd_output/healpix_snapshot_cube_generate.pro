PRO healpix_snapshot_cube_generate,obs_in,status_str,psf_in,cal,params,vis_arr,vis_model_arr=vis_model_arr,$
    file_path_fhd=file_path_fhd,ps_dimension=ps_dimension,ps_fov=ps_fov,ps_degpix=ps_degpix,$
    ps_kbinsize=ps_kbinsize,ps_kspan=ps_kspan,ps_beam_threshold=ps_beam_threshold,$
    rephase_weights=rephase_weights,n_avg=n_avg,flag_arr=flag_arr,split_ps_export=split_ps_export,$
    restrict_hpx_inds=restrict_hpx_inds,cmd_args=cmd_args,save_uvf=save_uvf,save_imagecube=save_imagecube,$
    snapshot_recalculate=snapshot_recalculate,_Extra=extra
    
  t0=Systime(1)
  
  IF N_Elements(silent) EQ 0 THEN silent=0
  IF N_Elements(status_str) EQ 0 THEN fhd_save_io,status_str,file_path_fhd=file_path_fhd,/no_save
  
  IF Keyword_Set(split_ps_export) THEN cube_name=['hpx_even','hpx_odd'] $
    ELSE cube_name='healpix_cube'
  
  IF N_Elements(obs_in) EQ 0 THEN fhd_save_io,status_str,obs_in,var='obs',/restore,file_path_fhd=file_path_fhd,_Extra=extra
  n_pol=obs_in.n_pol
  n_freq=obs_in.n_freq
  
;  IF not Keyword_Set(snapshot_recalculate) THEN BEGIN ;Now set in fhd_setup through status_str
    IF Keyword_Set(split_ps_export) THEN cube_test=Min(status_str.hpx_even[0:n_pol-1])<Min(status_str.hpx_odd[0:n_pol-1]) $
        ELSE cube_test=Min(status_str.healpix_cube[0:n_pol-1])
    IF cube_test GT 0 THEN RETURN
;  ENDIF
  
  IF N_Elements(psf_in) EQ 0 THEN fhd_save_io,status_str,psf_in,var='psf',/restore,file_path_fhd=file_path_fhd,_Extra=extra
  IF N_Elements(params) EQ 0 THEN fhd_save_io,status_str,params,var='params',/restore,file_path_fhd=file_path_fhd,_Extra=extra
  IF N_Elements(cal) EQ 0 THEN IF status_str.cal GT 0 THEN fhd_save_io,status_str,cal,var='cal',/restore,file_path_fhd=file_path_fhd,_Extra=extra
  
  IF N_Elements(n_avg) EQ 0 THEN n_avg=Float(Round(n_freq/48.)) ;default of 48 output frequency bins
  n_freq_use=Floor(n_freq/n_avg)
  IF Keyword_Set(ps_beam_threshold) THEN beam_threshold=ps_beam_threshold ELSE beam_threshold=0.2
  
  IF Keyword_Set(ps_kbinsize) THEN kbinsize=ps_kbinsize ELSE $
    IF Keyword_Set(ps_fov) THEN kbinsize=!RaDeg/ps_FoV ELSE kbinsize=obs_in.kpix
  FoV_use=!RaDeg/kbinsize
  
  IF Keyword_Set(ps_kspan) THEN dimension_use=ps_kspan/kbinsize ELSE $
    IF Keyword_Set(ps_dimension) THEN dimension_use=ps_dimension ELSE $
    IF Keyword_Set(ps_degpix) THEN dimension_use=FoV_use/ps_degpix ELSE dimension_use=FoV_use/obs_in.degpix
  
  degpix_use=FoV_use/dimension_use
  pix_sky=4.*!Pi*!RaDeg^2./degpix_use^2.
  Nside_chk=2.^(Ceil(ALOG(Sqrt(pix_sky/12.))/ALOG(2))) ;=1024. for 0.1119 degrees/pixel
  IF ~Keyword_Set(nside) THEN nside_use=Nside_chk
  nside_use=nside_use>Nside_chk
  IF Keyword_Set(nside) THEN nside_use=nside ELSE nside=nside_use
  
  obs_out=fhd_struct_update_obs(obs_in,n_pol=n_pol,nfreq_avg=n_avg,FoV=FoV_use,dimension=dimension_use)
  ps_psf_resolution=Round(psf_in.resolution*obs_out.kpix/obs_in.kpix)
  psf_out=beam_setup(obs_out,0,antenna_out,/no_save,psf_resolution=ps_psf_resolution,/silent,_Extra=extra)
  
  beam=Ptrarr(n_pol,n_freq_use,/allocate)
  beam_mask=fltarr(dimension_use,dimension_use)+1.
  FOR pol_i=0,n_pol-1 DO FOR fi=0L,n_freq_use-1 DO BEGIN
    *beam[pol_i,fi]=Sqrt(beam_image(psf_out,obs_out,pol_i=pol_i,freq_i=fi,/square)>0.)
    b_i=obs_out.obsx+obs_out.obsy*dimension_use
    beam_i=region_grow(*beam[pol_i,fi],b_i,thresh=[0,max(*beam[pol_i,fi])])
    beam_mask1=fltarr(dimension_use,dimension_use)
    beam_mask1[beam_i]=1.
    beam_mask*=beam_mask1
  ENDFOR
  
  hpx_cnv=healpix_cnv_generate(obs_out,file_path_fhd=file_path_fhd,nside=nside_use,$
    mask=beam_mask,restore_last=0,/no_save,hpx_radius=FoV_use/sqrt(2.),restrict_hpx_inds=restrict_hpx_inds)
  hpx_inds=hpx_cnv.inds
  n_hpx=N_Elements(hpx_inds)
  
  fhd_log_settings,file_path_fhd+'_ps',obs=obs_out,psf=psf_out,antenna=antenna_out,cal=cal,cmd_args=cmd_args,/overwrite
  undefine_fhd,antenna_out
  
  IF N_Elements(flag_arr) LT n_pol THEN fhd_save_io,status_str,flag_arr_use,var='flag_arr',/restore,file_path_fhd=file_path_fhd,_Extra=extra $
    ELSE flag_arr_use=Pointer_copy(flag_arr)
  flags_use=Ptrarr(n_pol,/allocate)
  
  IF Min(Ptr_valid(vis_arr)) EQ 0 THEN vis_arr=Ptrarr(n_pol,/allocate)
  IF N_Elements(*vis_arr[0]) EQ 0 THEN BEGIN
    FOR pol_i=0,n_pol-1 DO BEGIN
        fhd_save_io,status_str,vis_ptr,var='vis_ptr',/restore,file_path_fhd=file_path_fhd,obs=obs_out,pol_i=pol_i,_Extra=extra
        vis_arr[pol_i]=vis_ptr
    ENDFOR
  ENDIF
  
  IF Keyword_Set(split_ps_export) THEN BEGIN
    n_iter=2
    flag_arr_use=split_vis_flags(obs_out,flag_arr_use,bi_use=bi_use)
    vis_noise_calc,obs_out,vis_arr,flag_arr_use,bi_use=bi_use
    uvf_name = ['even','odd']
    if keyword_set(save_imagecube) then imagecube_filepath = file_path_fhd+['_even','_odd'] + '_gridded_imagecube.sav'
  ENDIF ELSE BEGIN
    n_iter=1
    bi_use=Ptrarr(n_iter,/allocate)
    *bi_use[0]=lindgen(nb)
    vis_noise_calc,obs_out,vis_arr,flag_arr_use
    uvf_name = ''
    if keyword_set(save_imagecube) then imagecube_filepath = file_path_fhd+'_gridded_imagecube.sav'
  ENDELSE
  
  residual_flag=obs_out.residual
  model_flag=0
  
  IF Min(Ptr_valid(vis_model_arr)) THEN IF N_Elements(*vis_model_arr[0]) GT 0 THEN model_flag=1
  IF residual_flag EQ 0 THEN IF model_flag EQ 0 THEN BEGIN
    vis_model_arr=Ptrarr(n_pol)
    IF Min(status_str.vis_model[0:n_pol-1]) GT 0 THEN BEGIN
        model_flag=1
        FOR pol_i=0,n_pol-1 DO BEGIN
            fhd_save_io,status_str,vis_model_ptr,var='vis_model_ptr',/restore,file_path_fhd=file_path_fhd,obs=obs_out,pol_i=pol_i,_Extra=extra
            vis_model_arr[pol_i]=vis_model_ptr
        ENDFOR 
    ENDIF
  ENDIF
  IF model_flag AND ~residual_flag THEN dirty_flag=1 ELSE dirty_flag=0
  
  t_hpx=0.
  t_split=0.
  obs_out_ref=obs_out
  obs_in_ref=obs_in
  FOR iter=0,n_iter-1 DO BEGIN
    FOR pol_i=0,n_pol-1 DO BEGIN
      flag_arr1=fltarr(size(*flag_arr_use[pol_i],/dimension))
      flag_arr1[*,*bi_use[iter]]=(*flag_arr_use[pol_i])[*,*bi_use[iter]]
      *flags_use[pol_i]=flag_arr1
    ENDFOR
    obs=obs_out ;will have some values over-written!
    psf=psf_out
    
    residual_arr1=vis_model_freq_split(obs_in,status_str,psf_in,params,flags_use,obs_out=obs,psf_out=psf,/rephase_weights,$
      weights_arr=weights_arr1,variance_arr=variance_arr1,model_arr=model_arr1,n_avg=n_avg,timing=t_split1,/fft,$
      file_path_fhd=file_path_fhd,vis_n_arr=vis_n_arr,/preserve_visibilities,vis_data_arr=vis_arr,vis_model_arr=vis_model_arr,$
      save_uvf=save_uvf, uvf_name=uvf_name[iter])
    t_split+=t_split1
    IF dirty_flag THEN BEGIN
      dirty_arr1=residual_arr1
      residual_arr1=Ptrarr(size(residual_arr1,/dimension),/allocate)
    ENDIF
    
    residual_hpx_arr=Ptrarr(n_pol,n_freq_use,/allocate)
    model_hpx_arr=Ptrarr(n_pol,n_freq_use,/allocate)
    dirty_hpx_arr=Ptrarr(n_pol,n_freq_use,/allocate)
    weights_hpx_arr=Ptrarr(n_pol,n_freq_use,/allocate)
    variance_hpx_arr=Ptrarr(n_pol,n_freq_use,/allocate)
    beam_hpx_arr=Ptrarr(n_pol,n_freq_use,/allocate)
    t_hpx0=Systime(1)
    FOR pol_i=0,n_pol-1 DO FOR freq_i=0,n_freq_use-1 DO BEGIN
      *weights_hpx_arr[pol_i,freq_i]=healpix_cnv_apply((*weights_arr1[pol_i,freq_i]),hpx_cnv)
      *variance_hpx_arr[pol_i,freq_i]=healpix_cnv_apply((*variance_arr1[pol_i,freq_i]),hpx_cnv)
      IF dirty_flag THEN *residual_arr1[pol_i,freq_i]=*dirty_arr1[pol_i,freq_i]-*model_arr1[pol_i,freq_i]
      *residual_hpx_arr[pol_i,freq_i]=healpix_cnv_apply((*residual_arr1[pol_i,freq_i]),hpx_cnv)
      IF dirty_flag THEN *dirty_hpx_arr[pol_i,freq_i]=healpix_cnv_apply((*dirty_arr1[pol_i,freq_i]),hpx_cnv)
      IF model_flag THEN *model_hpx_arr[pol_i,freq_i]=healpix_cnv_apply((*model_arr1[pol_i,freq_i]),hpx_cnv)
      *beam_hpx_arr[pol_i,freq_i]=healpix_cnv_apply((*beam[pol_i,freq_i])^2.,hpx_cnv)
    ENDFOR
    t_hpx+=Systime(1)-t_hpx0
    
    if keyword_set(save_imagecube) then $
      save, filename = imagecube_filepath[iter], dirty_arr1, residual_arr1, model_arr1, weights_arr1, variance_arr1, obs_out, /compress
      
    FOR pol_i=0,n_pol-1 DO BEGIN      
        IF dirty_flag THEN BEGIN
          dirty_cube=fltarr(n_hpx,n_freq_use)
            ;write index in much more efficient memory access order
          FOR fi=0L,n_freq_use-1 DO dirty_cube[n_hpx*fi]=Temporary(*dirty_hpx_arr[pol_i,fi])
        ENDIF
        
        IF model_flag THEN BEGIN
          model_cube=fltarr(n_hpx,n_freq_use)
          FOR fi=0L,n_freq_use-1 DO model_cube[n_hpx*fi]=Temporary(*model_hpx_arr[pol_i,fi])
        ENDIF
        
        res_cube=fltarr(n_hpx,n_freq_use)
        FOR fi=0L,n_freq_use-1 DO res_cube[n_hpx*fi]=Temporary(*residual_hpx_arr[pol_i,fi])
        
        weights_cube=fltarr(n_hpx,n_freq_use)
        FOR fi=0L,n_freq_use-1 DO weights_cube[n_hpx*fi]=Temporary(*weights_hpx_arr[pol_i,fi])
        
        variance_cube=fltarr(n_hpx,n_freq_use)
        FOR fi=0L,n_freq_use-1 DO variance_cube[n_hpx*fi]=Temporary(*variance_hpx_arr[pol_i,fi])
        
        beam_cube=fltarr(n_hpx,n_freq_use)
        FOR fi=0L,n_freq_use-1 DO beam_cube[n_hpx*fi]=Temporary(*beam_hpx_arr[pol_i,fi])
        
        ;call fhd_save_io first to obtain the correct path. Will NOT update status structure yet
        fhd_save_io,status_str,file_path_fhd=file_path_fhd,var=cube_name[iter],pol_i=pol_i,path_use=path_use,/no_save,_Extra=extra 
        save,filename=path_use,/compress,dirty_cube,model_cube,weights_cube,variance_cube,res_cube,beam_cube,$
            obs,nside,hpx_inds,n_avg
        ;call fhd_save_io a second time to update the status structure now that the file has actually been written
        fhd_save_io,status_str,file_path_fhd=file_path_fhd,var=cube_name[iter],pol_i=pol_i,/force,_Extra=extra 
        dirty_cube=(model_cube=(res_cube=(weights_cube=(variance_cube=(beam_cube=0)))))
    ENDFOR
    undefine_fhd,dirty_hpx_arr,model_hpx_arr,residual_hpx_arr,weights_hpx_arr,variance_hpx_arr,beam_hpx_arr
ENDFOR
Ptr_free,flag_arr_use
timing=Systime(1)-t0
IF ~Keyword_Set(silent) THEN print,'HEALPix cube export timing: ',timing,t_split,t_hpx
END