        dosseg

data    segment byte public 'data'
  credits       db      "LOADER CLASS 101",13,10
                db      "Taught By - Sauron THG F/X Prez$"

  palbegin      db      221                 ; color to start at for cycling
  palbegincx    dw      221*3               ; palbegin * 3
  palcx         dw      20*3                ; # of colors to cycle *3

  paltmp3       db      3 dup (0)           ;
  paltmp        db      256*3 dup (0)

  paltmp2       db      256*3 dup (0)       ; tempory pallete
  fadepoint     db      64                  ; # of times to darken pallete
data    ends

picture segment byte public 'data'
  pal           db        768 dup (0)
  pic           db      64000 dup (0)
picture ends

stacks  segment byte stack 'stack'
  thestak 	db      256 dup (0h)
stacks  ends

code    segment byte public 'code'
        assume  cs:code, ds:data, ss:stacks
start:  jmp	main

PalleteRotate proc near
        mov     ax,data
        mov     es,ax
	mov	ds,ax

PDN:    mov     cx,[palcx]
        mov     di,offset paltmp3           ;to here
        mov     si,offset paltmp            ;from here
        rep     movsb
        mov     cx,3
        mov     si,offset paltmp3
        rep     movsb

        mov     dx,03dah
vr1:    in      al,dx
        and     al,08
        jz      vr1
        mov     al,[palbegin]
        mov     dx,03c8h
        out     dx,al
        inc     dx
        mov     cx,[palcx]
        mov     si,offset paltmp
pl13:   lodsb
        out     dx,al
        loop    pl13

        ret
PalleteRotate endp

FADEOUT 	proc
        mov     ax,data
        mov     ds,ax
        mov     es,ax

        mov     ax,picture
        mov     ds,ax
        mov     cx,768/2
        mov     si,offset pal
        mov     di,offset paltmp
        rep     movsw
        mov     ax,data
        mov     ds,ax
        mov     es,ax
flp1:   mov     bx,768
flp2:   cmp     paltmp[bx],0
        je      fl3
        dec     paltmp[bx]
fl3:    dec     bx
        jnz     flp2
        mov     dx,offset paltmp
        mov     ax,1012h
        mov	bx,0
        mov     cx,256
        int     10h
        dec     [fadepoint]
        jnz     flp1

endfadeout:	ret
FADEOUT	endp

;========================================================================

MAIN:   mov     ax,0013h
        int     10h

        mov     ax,picture      ;BEGIN setup pallete
        mov     es,ax
	mov	ds,ax
        mov     dx,offset pal
        mov     ax,1012h
        mov	bx,0
        mov     cx,256
        int     10h             ;END   setup pallete

        mov     ax,picture      ;BEGIN copy picture to vga card.
        mov     ds,ax
        mov     ax,0a000h
        mov     es,ax
        mov     di,0
        mov     si,offset pic
        mov     cx,64000/2
        rep     movsw           ;END   copy picture to vga card.


        mov     ax,data               ;copy pallete to temp for rotating pal
        mov     ds,ax
        mov     cx,[palcx]
        mov     dx,[palbegincx]
        mov     ax,picture
        mov     ds,ax
        mov     ax,data
        mov     es,ax
        mov     si,offset pal
        add     si,dx
        mov     di,offset paltmp
        rep     movsb                 ;end copy pallete


HERE:   call    PalleteRotate         ;after polling they keyboard, it calls
                                      ;the pallete rotating procedure

	mov	ah,1
	int	16h
	jz	HERE
	mov	ah,0
	int	16h

        call    fadeout

        mov     ax,0003
        int     10h
	mov	ax,data
	mov	ds,ax
        mov     ah,9                  ; used to display a string of text.
                                      ; uses a $ to end text.
        mov     dx,offset credits     ; starting byte of text.
        int     21h                   ; if ah = 9 then display text
        mov     ax,4c00h
        int     21h

code    ends
        end     start



The 2 major new procedures are PALLETE CYCLING and FADEOUT.  Here they are
in detail.
1)  PALLETE CYCLING.  1st I have it copy just the section of the pallete
    that we are going to rotate to a buffer. Now to the actual
    palleterotate procedure.  Basically, the 1st section shifts the section
    of the pallete DOWN by 1.  Then it takes the 3 bottom bytes and puts
    them at the top.  This is to make sure you keep the pallete rotating
    and not just shift them all off the bottom.

        mov     ax,data
        mov     ds,ax
        mov     es,ax
        mov     cx,[palcx]
        mov     di,offset paltmp3           ;to here
        mov     si,offset paltmp            ;from here
        rep     movsb
        mov     cx,3
        mov     si,offset paltmp3
        rep     movsb

    The next section writes directly to the vga card.
    Here is what this procedure does:

        mov     dx,03dah                ; check for vertical retrace
vr1:    in      al,dx                   ;
        and     al,08                   ;
        jz      vr1                     ; end checking section

        mov     al,[palbegin]
        mov     dx,03c8h
        out     dx,al
        inc     dx
        mov     cx,[palcx]
        mov     si,offset paltmp
pl13:   lodsb
        out     dx,al
        loop    pl13

    1st, we check for vertical retrace to be sure we don't get "SNOW" on
    the screen.  For direct pallete cycling, you must have these registers
    setup first:
      AL - # to start cycling colors
