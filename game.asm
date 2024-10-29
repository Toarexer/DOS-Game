global _start
org 0x100


; Console dimentions
%define WIDTH  80
%define HEIGHT 25


; Services
%define BIOS_VIDEO 0x10
%define BIOS_MISC  0x15
%define BIOS_KEYB  0x16
%define BIOS_RTC   0x1A
%define DOS_API    0x21


; Colors
%define FGC_BLACK  0x00
%define FGC_RED    0x04
%define FGC_GRAY   0x08
%define FGC_LGREEN 0x0A
%define BGC_GRAY   0x70


; Video - Set Cursor Shape
%define F_SET_CSR_SHAPE 0x01

; Video - Set Cursor Position
%define F_SET_CSR_POS 0x02

; Video - Write Character and Attribute at Cursor
%define F_WRT_CHR_ATTR 0x09

; Misc - Wait
%define F_WAIT 0x86

; Keyboard - Read key press
%define F_READ_KEY 0x00

; Keyboard - Get the State of the keyboard buffer
%define F_READ_IN_STAT 0x01

; RTC - Read real-time clock
%define F_READ_RTC 0x00

; DOS - Display string
%define F_DISPLAY_STR 0x09

; DOS - Terminate with return code
%define F_EXIT 0x4C


; map borders
%define MAP_UPPER_WALL 6
%define MAP_LOWER_WALL 19
%define MAP_HEIGHT HEIGHT-MAP_UPPER_WALL

; player character
%define PLAYER_CHR 0x01

; obstacle character
%define OBSTACLE_CHR 0x11
; %define OBSTACLE_CHR 0xDB

; ---------------- UTILITY MACROS ---------------- ;

%macro set_func 1
	xor al, al
	mov ah, %1
%endmacro

%macro set_func 2
	mov al, %2
	mov ah, %1
%endmacro

%macro modify_pp 2
	mov ax, %1
	mov bx, %2
	call modify_player_pos
%endmacro

; ---------------- INTERRUPT MACROS ---------------- ;

%macro hide_cursor 0
	set_func F_SET_CSR_SHAPE
	mov cx, 0x2607				; scan row (0x2607 -> hidden cursor)
	int BIOS_VIDEO
%endmacro

%macro set_curpos 2
	set_func F_SET_CSR_POS
	xor bh, bh					; page number
	mov dl, %1					; x
	mov dh, %2					; y
	int BIOS_VIDEO
%endmacro

%macro print_chr 2
	print_chr %1, %2, 1
%endmacro

%macro print_chr 3
	set_func F_WRT_CHR_ATTR, %1
	xor bh, bh					; page number
	mov bl, %2					; color
	mov cx, %3					; n
	int BIOS_VIDEO
%endmacro

%macro fill_rows 3
	set_curpos 0, %2
	print_chr ' ', %1, WIDTH*%3
%endmacro

%macro display_string 2
	print_chr ' ', %1, WIDTH*%3
%endmacro

; ---------------- DATA SECTION ---------------- ;

section .data

	loop_wait dw 100			; 100 miliseconds
	loop_iter dw 0				; current cycle
	loop_imax dw 30				; max cycles

	player_x dw 3
	player_y dw HEIGHT/2
	player_direction db 0

	obstacles
	%rep MAP_HEIGHT
		dw 0
	%endrep

	score dw 0
	score_str db 'SCORE: '
	score_str_val db '00000', 0

	is_game_over db 0

; ---------------- TEXT SECTION ---------------- ;

section .text

; ---------------- ENTRY POINT ---------------- ;

_start:
	hide_cursor

game_loop:
	call game_loop_input

	inc word [loop_iter]
	mov ax, [loop_imax]

	cmp [loop_iter], ax
	jl game_post_update

	xor al, al
	cmp [is_game_over], al
	jne game_post_update

	mov [loop_iter], word 0

game_update:
	call game_loop_print_map
	call game_loop_print_score
	call game_loop_update_player
	call game_loop_update_obstacles
	mov [player_direction], byte 0
	inc word [score]

game_post_update:
	call game_loop_wait
	jmp game_loop

; ---------------- Input ---------------- ;

game_loop_input:
	set_func F_READ_IN_STAT
	int BIOS_KEYB
	jz no_keys_pressed

	set_func F_READ_KEY
	int BIOS_KEYB

	cmp al, 'w'
	jne no_up_pressed
	mov [player_direction], byte 1
	ret
no_up_pressed:

	cmp al, 'd'
	jne no_right_pressed
	mov [player_direction], byte 2
	ret
no_right_pressed:

	cmp al, 's'
	jne no_down_pressed
	mov [player_direction], byte 3
	ret
no_down_pressed:

	cmp al, 'a'
	jne no_left_pressed
	mov [player_direction], byte 4
	ret
no_left_pressed:

	cmp ah, 0x01				; Escape key
	jne no_keys_pressed
	set_func F_EXIT
	int DOS_API

no_keys_pressed:
	ret

; ---------------- Print Map ---------------- ;

game_loop_print_map:
	fill_rows BGC_GRAY, 0, MAP_UPPER_WALL
	fill_rows FGC_BLACK, MAP_UPPER_WALL, MAP_HEIGHT
	fill_rows BGC_GRAY, MAP_LOWER_WALL, MAP_UPPER_WALL
	ret

; ---------------- Update Player ---------------- ;

game_loop_update_player:
	mov al, [player_direction]

	cmp al, 1
	jne no_up_move
	modify_pp 0, -1
	jmp update_player_end
no_up_move:

	cmp al, 2
	jne no_right_move
	modify_pp +1, 0
	jmp update_player_end
no_right_move:

	cmp al, 3
	jne no_down_move
	modify_pp 0, +1
	jmp update_player_end
no_down_move:

	cmp al, 4
	jne no_left_move
	modify_pp -1, 0
no_left_move:

update_player_end:
	set_curpos byte [player_x], byte [player_y]
	print_chr PLAYER_CHR, FGC_LGREEN
	ret

; ---------------- Update Player Position ---------------- ;
; ax - added to player x
; bx - added to player y

modify_player_pos:
	add ax, [player_x]
	add bx, [player_y]

	cmp ax, 0
	jge not_oolb
	xor ax, ax
not_oolb:

	cmp ax, WIDTH
	jl not_oorb
	mov ax, WIDTH-1
not_oorb:

	cmp bx, MAP_UPPER_WALL
	jge not_ootb
	mov bx, MAP_UPPER_WALL
not_ootb:

	cmp bx, MAP_LOWER_WALL
	jl not_oobb
	mov bx, MAP_LOWER_WALL-1
not_oobb:

	mov [player_x], ax
	mov [player_y], bx
	ret

; ---------------- Update Obstacles ---------------- ;

game_loop_update_obstacles:
	mov ax, MAP_UPPER_WALL
	xor si, si

obstacles_loop:
	push ax
	call update_obstacle_pos

	pop ax
	cmp [player_y], ax
	jne no_obstacle_hit

	mov bx, [obstacles+si]
	cmp [player_x], bx
	jne no_obstacle_hit

	call game_over

no_obstacle_hit:
	inc ax
	add si, 2

	cmp ax, MAP_HEIGHT
	jl obstacles_loop
	ret

; ---------------- Update Obstacle Position ---------------- ;
; ax - index of console row
; si - index of the obstacle

update_obstacle_pos:
	cmp word [obstacles+si], 0
	jle reset_obstacle

	dec word [obstacles+si]
	cmp word [obstacles+si], WIDTH
	jl draw_obstacle
	ret

reset_obstacle:
	push ax
	set_func F_READ_RTC
	int BIOS_RTC
	pop ax

	xor ax, dx
	xor dx, dx
	mov bx, 11
	div bx
	inc dx

	mov ax, dx
	mov bx, 10
	mul bx
	add ax, WIDTH

	mov [obstacles+si], ax
	ret

draw_obstacle:
	mov cl, al
	set_curpos byte [obstacles+si], cl
	print_chr OBSTACLE_CHR, FGC_RED
	ret

; ---------------- Print Score ---------------- ;

game_loop_print_score:
	call score_to_string
	mov cx, 2
	xor si, si

print_next_chr:
	set_curpos cl, MAP_UPPER_WALL-2
	push cx
	print_chr [score_str+si], BGC_GRAY
	pop cx

	inc cx
	inc si
	cmp [score_str+si], byte 0
	jne print_next_chr
	ret

; ---------------- Convert Score to String ---------------- ;

score_to_string:
	mov ax, [score]
	mov si, 4

next_digit:
	xor dx, dx
	mov bx, 10
	div bx

	add dl, '0'
	mov [score_str_val+si], dl

	dec si
	cmp [score_str_val+si], byte ' '
	jne next_digit
	ret

; ---------------- Wait ---------------- ;

game_loop_wait:
	set_func F_WAIT				; Docs say it uses microseconds? 
	mov cx, word 0				; miliseconds (high)
	mov dx, word [loop_wait]	; miliseconds (low)
	int BIOS_MISC
	ret

; ---------------- Game Over ---------------- ;

game_over:
	; TODO: Game over screen instead of exit
	mov [is_game_over], byte 1
	ret
