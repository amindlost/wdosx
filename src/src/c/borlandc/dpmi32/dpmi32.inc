
RealModePtr		struc

			RmOffset	dw ?
			RmSegment	dw ?

RealModePtr		ends

ProtModePtr		struc

			PmOffset	dd ?
			PmSelector	dd ?

ProtModePtr		ends


RmCallStruc	struc

		_edi	label	dword
		_di	dw	?
			dw	?
		_esi	label	dword
		_si	dw	?
			dw	?
		_ebp	label	dword
		_bp	dw	?
			dw	?
		_esp	label	dword
		_spl	dw	?
			dw	?
		_ebx	label	dword
		_bx	label	word
		_bl	db	?
		_bh	db	?
			dw	?
		_edx	label	dword
		_dx	label	word
		_dl	db	?
		_dh	db	?
			dw	?
		_ecx	label	dword
		_cx	label	word
		_cl	db	?
		_ch	db	?
			dw	?
		_eax	label	dword
		_ax	label	word
		_al	db	?
		_ah	db	?
			dw	?
		_flags	dw	?
		_es	dw	?
		_ds	dw	?
		_fs	dw	?
		_gs	dw	?
		_ip	dw	?
		_cs	dw	?
		_sp	dw	?
		_ss	dw	?	

RmCallStruc	ends

