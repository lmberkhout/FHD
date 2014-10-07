FUNCTION beam_width_calculate,obs,min_restored_beam_width=min_restored_beam_width,fwhm=fwhm

;calculates the approximate FWHM of a PSF from the maximum baseline of an instrument

;factor of (2.*Sqrt(2.*Alog(2.))) is to convert FWHM and sigma of gaussian
beam_width=!RaDeg/(obs.MAX_BASELINE/obs.KPIX)/obs.degpix
IF N_Elements(beam_width) GT 1 THEN beam_width=Median(beam_width,/even)
IF ~Keyword_Set(fwhm) THEN beam_width/=2.*Sqrt(2.*Alog(2.))
IF N_Elements(min_restored_beam_width) EQ 0 THEN min_restored_beam_width=0.75
IF Keyword_Set(min_restored_beam_width) THEN beam_width=beam_width>min_restored_beam_width

RETURN,beam_width

END