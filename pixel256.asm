; Pixel 256, F#READY, 2018-10-31
; Pixel plotter, shows 256 moving pixels in not realtime, but close enough ;)

; uses gr.7, where the screen memory is aligned to 32 bytes (not the case for gr.8!)

; v1 - version based on cleartest, 256 bytes exaclty! without post-optimisation
; v2 - more interesting shape
; v3 - add timing info, prepare to replace clean routine, sound to consol speaker :)
; v4 - replace clear routine with store/restore, inlined subroutines, now 252 bytes
; v5 - re-use plot and unplot with eor pixel, 228 bytes!
; v5.1 - multi fx, patch to get other shapes
; v5.2 - code cleanup, optimised line lookup, adds eor patch after 255 jiffies, 256 bytes!
; v5.3 - optimised, now 251 bytes
; v5.4 - few optimised bytes, but used for another fx-patch after 16 shapes, 256 bytes!
; v5.5 - code cleanup for source code release

			org $4000

tmp_zp		= $cb	; $cc

line_tab_lo	= $2000
line_tab_hi	= $2100
sinewave	= $2200		; to $22ff

scrmem		= 88	; 89
			
main		jsr graphics

			dec 559

			ldx #0
			ldy #$3f
make_sine
value_lo
			lda #0
  			clc
delta_lo
  			adc #0
  			sta value_lo+1
value_hi
  			lda #0
delta_hi
  			adc #0
  			sta value_hi+1
 
  			sta sinewave+$c0,x
  			sta sinewave+$80,y
  			eor #$7f
  			sta sinewave+$40,x
  			sta sinewave+$00,y
 
  			lda delta_lo+1
  			adc #8
  			sta delta_lo+1
  			bcc nothi
   			inc delta_hi+1
nothi
  			inx
  			dey
 			bpl make_sine

; generate line lookup tables
			
gen_line_tab
			ldx #0
more_tab
			lda 88
			sta line_tab_lo,x
			clc
			adc #32
			sta 88

			lda 89
			sta line_tab_hi,x
			bcc no_hi_inc			
			inc 89
no_hi_inc
			inx
			bne more_tab
			
; start main loop....

wt_vbdone
			lda $d40b
			bne wt_vbdone
			sta 20
			sta $d40e
			
; shape movement
move_loop
			inc 20
			bne not_finish
			lda eor_patch+1
			eor #$99
			sta eor_patch+1
not_finish
			lda 20
			and #63
			bne wait_dot
			
fx_count_lda
			lda #0			; fx_count
			tax
			and #16
			beq blip
			inc fx3_patch+1
blip
			lda $e240,x
			
			and #15
fx3_patch
			ora #1
;			tay
			sta fx1_patch+1
			
			lda $e200,x
			eor #$30
			ora #8
			sta $d018
						
			inc fx_count_lda+1	; fx_count
wait_dot
			jsr plot_unplot
			jsr plot_unplot

			inc sinx_start_adc+1	; sinx_start
			jmp move_loop

; plot / unplot all pixels
plot_unplot
loop
			lda $d40b
			cmp #92
			bne loop

			ldy #0
plot_more
			tya
			pha				; save plot index

sinx_index_lda
			lda #0			; sinx_index
			clc
fx1_patch
			adc #192
			sta sinx_index_lda+1	; sinx_index
sinx_start_adc
			adc #0					; sinx_start

			tax
			lda sinewave,x
			pha
eor_patch
			eor #0		; eor causes some speciol fx

			sta $d01f	; trademark musix :P

			lsr
			lsr			; div 4, a = course x position
			tay
			
siny_index_ldx
			ldx #0					; siny_index
			inx
			inx
			inx
			stx siny_index_ldx+1	; siny_index

			lda sinewave,x
			lsr					; a = plot y-position (0-63)

			tax
			lda line_tab_lo,x
			sta tmp_zp
			lda line_tab_hi,x
			sta tmp_zp+1

			pla
			and #3
			tax

			lda (tmp_zp),y
			eor pixel_tab,x
			sta (tmp_zp),y

			pla			; plot index
			tay
			dey
			bne plot_more
			
; finish
			rts

graphics
			lda $e411
			pha
			lda $e410
			pha

			lda #7
			sta $2b	; ICAX2Z

			rts

pixel_tab
			dta %11000000
			dta %00110000
			dta %00001100
			dta %00000011

			run main