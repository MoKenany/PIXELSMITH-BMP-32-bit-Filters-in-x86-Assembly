.MODEL SMALL
.STACK 100h

.DATA
    ; --- User Interface Messages --- (13)=> Carriage Return & (10)=> Line Feed
    menuMsg         DB '--- BMP Image Filter Program (Optimized v2) ---', 13, 10
                    DB 'Please choose a filter to apply:', 13, 10
                    DB '1. Invert Colors (for 4-bit, 16-color BMP)', 13, 10
                    DB '2. Grayscale (for 24-bit BMP)', 13, 10
                    DB '3. Grayscale (for 32-bit BGRA BMP)', 13, 10
                    DB '4. Binary (Black & White for 32-bit BGRA BMP)', 13, 10
                    DB 'Your choice: $'
    successMsg      DB 'Operation completed successfully!$', 13, 10
    failureMsg      DB 'Operation failed. Check input file or permissions.$', 13, 10
    invalidChoiceMsg DB 'Invalid choice. Please run the program again.$', 13, 10

    ; --- File Names ---
    inputFileName   DB 'input.bmp', 0
    outputInvert    DB 'inverted.bmp', 0
    outputLightGrey DB 'light_grey.bmp', 0
    outputGrey      DB 'grey.bmp', 0
    outputBinary    DB 'binary.bmp', 0

    ; --- File and Data Variables ---
    inHandle        DW ?                ; Handle for the input file
    outHandle       DW ?                ; Handle for the output file
    header          DB 54 DUP(?)        ; Buffer to store the 54-byte BMP header
    buffer          DB 63000 DUP(?)     ; A 63KB buffer to process image data in chunks
    userChoice      DB ?                ; Stores the user's filter choice => [ 1 , 2 , 3 , 4 ]

.CODE
MAIN PROC
    ; Initialize Data Segment (DS) register  .STARTUP 
    mov ax, @data
    mov ds, ax

    ; --- Display Menu and Get User Input ---
    mov ah, 09h                                ; INT for print string on screen => OFFSET from DX
    lea dx, menuMsg
    int 21h

    mov ah, 01h                               ; INT reading char from keyboard => input in AL
    int 21h
    mov [userChoice], al

    ; --- Route to the correct filter based on user choice ---
    cmp al, '1'                                             
    je  Setup_Invert
    cmp al, '2'
    je  Setup_LightGrey
    cmp al, '3'
    je  Setup_Grey                            ; Simulate Switch Case
    cmp al, '4'
    je  Setup_Binary

    jmp Invalid_Choice                        ; Handel invalid choices

; --- Setup Blocks for Each Filter ---
Setup_Invert:
    lea dx, outputInvert        ;Load (output file name) OFFSET in DX , Get raedy for INT Print
    jmp Open_Files
Setup_LightGrey:
    lea dx, outputLightGrey
    jmp Open_Files
Setup_Grey:
    lea dx, outputGrey
    jmp Open_Files
Setup_Binary:
    lea dx, outputBinary
    jmp Open_Files

; --- Common File Handling ---
Open_Files:
    push dx                    ; Save output filename pointer in our STACK => 100h
    mov ah, 3Dh
    mov al, 0                  ; Mode of File Here => ( 0 ) For Read Only from file 
    lea dx, inputFileName
    int 21h
    jnc open_ok                ; AX now have the ( File ID or Handel )  Source File
    pop dx
    jmp Exit_Failure
open_ok:
    mov inHandle, ax            ; Save File ID in Var  Input file
    pop dx                      ; Restore output filename pointer
    mov ah, 3Ch                 ; For (Create or Overwrite) Files
    mov cx, 0                   ; File Attributes ( 0 )=> Normal File
    int 21h
    jnc create_ok               ; AX now have the ( File ID or Handel )  Destination File
    jmp Exit_Failure
create_ok:
    mov outHandle, ax           ; Save File ID in Var  Output file

    ; --- Read and Write the 54-byte BMP Header ---
    mov ah, 3Fh               ; Read from File and Write into Memory at OFFSET => DX
    mov bx, inHandle          ; ID of file => BX Input
    mov cx, 54                ; # Bytes to Read 
    lea dx, header            ; The OFFSET on Memory to Write in 
    int 21h

    mov ah, 40h               ; Read from Memory OFFSET => DX and Write into File 
    mov bx, outHandle         ; ID of file => BX Output
    mov cx, 54                ; # Bytes to Write
    lea dx, header            ; The OFFSET on Memory to Read from
    int 21h

    ; --- Jump to the chosen filter's processing loop ---
    mov al, [userChoice]
    cmp al, '1'
    jne check_2
    jmp Start_Invert_Filter
check_2:
    cmp al, '2'
    jne check_3
    jmp Start_LightGrey_Filter
check_3:
    cmp al, '3'
    jne check_4
    jmp Start_Grey_Filter
check_4:
    jmp Start_Binary_Filter
; ----------------------------------------------------------------------
; TO Avoid (Branch Prediction Failure)  Error Relative Jump Out Of Range
; ----------------------------------------------------------------------
;    mov al, [userChoice]
;    cmp al, 1
;    je Start_Invert_Filter
    
;    cmp al, 2
;    je Start_LightGrey_Filter

;    cmp al, 3
;    je Start_Grey_Filter
    
;    ;cmp al, 4
;    jmp Start_Binary_Filter
; ----------------------------------------------------------------------


; =============================================================================
; == FILTER 1: INVERT COLORS (4-bit BMP) [OPTIMIZED]                         ==
; =============================================================================
Start_Invert_Filter:
    ; Read/Write 64-byte color palette (if it exists)
    mov ah, 3Fh
    mov bx, inHandle
    mov cx, 64
    lea dx, buffer
    int 21h
    mov ah, 40h
    mov bx, outHandle
    mov cx, 64
    lea dx, buffer
    int 21h
Invert_Read_Loop:
    mov ah, 3Fh
    mov bx, inHandle
    mov cx, SIZE buffer             ;CX => 63 X 1024 = 64,512 AS a Number
    lea dx, buffer
    int 21h                         ;AX => have the actual Number of Valid Bytes to be Read 
    jnc invert_read_ok
    jmp Exit_Failure
invert_read_ok:
    or ax, ax                   ;Check ax = 0 update Flags (ZF) Faster than CMP AX,0
    jnz invert_process_chunk    ;Check if we reach the end of the file or not 
    jmp Exit_Success
invert_process_chunk:
    mov cx, ax                  ; Store the actual size of readed bytes.
    mov si, 0
Invert_Process_Loop:
    cmp si, cx
    jae Invert_Write_Loop
    
    ; --- OPTIMIZATION ---
    ; Invert byte,invert one color ( R , G , B , Hue )in a single instruction.
    ; One Pixel run that 4 Times
    xor byte ptr [buffer + si], 0FFh 
    
    inc si                      ;INC with 1-Byte Value
    jmp Invert_Process_Loop
Invert_Write_Loop:
    mov ah, 40h
    mov bx, outHandle
    mov cx, si                  ;Actual #Bytes be processed.
    lea dx, buffer
    int 21h
    jmp Invert_Read_Loop       ;Return to take the next chunk.

; =============================================================================
; == FILTER 2: LIGHT GREYSCALE (24-bit BMP) [OPTIMIZED v2]                   ==
; =============================================================================
Start_LightGrey_Filter:
LightGrey_Read_Loop:
    mov ah, 3Fh
    mov bx, inHandle
    mov cx, SIZE buffer
    lea dx, buffer
    int 21h
    jnc lightgrey_read_ok
    jmp Exit_Failure
    lightgrey_read_ok:
    or ax, ax                       ;Sure AX not Zero => cmp AX,0 ,But Faster
    jnz lightgrey_process_chunk
    jmp Exit_Success
lightgrey_process_chunk:
    mov cx, ax
    mov si, 0
LightGrey_Process_Loop:
    cmp si, cx
    jae LightGrey_Write_Loop

    ; --- Use 16-bit sum (Your correct original logic) ---
    xor ax, ax                ; AX = 0
    mov al, [buffer + si]     ; AL = B
    xor bx, bx                ; BX = 0
    mov bl, [buffer + si + 1] ; BL = G
    add ax, bx                ; AX = B+G
    mov bl, [buffer + si + 2] ; BL = R
    add ax, bx                ; AX = B+G+R (Max 765)
    
    ; --- OPTIMIZATION v2: Replace slow DIV with fast MUL/SHR ---
    ; AL = (AX * 85) / 256 --> shift 8 -->  = (B+G+R)/3
    mov bx, 85                ; Load multiplier
    mul bx                    ; DX:AX = AX * 85 (Result is max 65025, so DX=0) 65,535
    shr ax, 8                 ; Fast divide by 256 (AL = AH)
    ; Result is now in AL     Shift Right AX by 8 bits
    
    ; Store the gray value
    mov [buffer + si], al
    mov [buffer + si + 1], al
    mov [buffer + si + 2], al
    
    add si, 3               
    jmp LightGrey_Process_Loop
LightGrey_Write_Loop:
    mov ah, 40h
    mov bx, outHandle
    mov cx, si
    lea dx, buffer
    int 21h
    jmp LightGrey_Read_Loop

; =============================================================================
; == FILTER 3: GREYSCALE (32-bit BMP) [BUGFIX + OPTIMIZED v2]                ==
; =============================================================================
Start_Grey_Filter:
Grey_Read_Loop:
    mov ah, 3Fh
    mov bx, inHandle
    mov cx, SIZE buffer
    lea dx, buffer
    int 21h
    jnc grey_read_ok
    jmp Exit_Failure
grey_read_ok:
    or ax, ax
    jnz grey_process_chunk
    jmp Exit_Success
grey_process_chunk:
    mov cx, ax
    mov si, 0
Grey_Process_Loop:
    cmp si, cx
    jae Grey_Write_Loop
    
    ; Preserve Alpha channel
    mov dh, [buffer + si + 3]

    ; --- BUGFIX: Use AX for sum to prevent overflow ---
    xor ax, ax                ; AX = 0
    mov al, [buffer + si]     ; AL = B
    xor bx, bx                ; BX = 0
    mov bl, [buffer + si + 1] ; BL = G
    add ax, bx                ; AX = B+G
    mov bl, [buffer + si + 2] ; BL = R
    add ax, bx                ; AX = B+G+R
    
    ; --- OPTIMIZATION v2: Replace slow DIV with fast MUL/SHR ---
    mov bx, 85
    mul bx                    ; DX:AX = AX * 85
    shr ax, 8                 ; AL = AH
    ; Result is now in AL

    ; Store the gray value, restore alpha
    mov [buffer + si], al
    mov [buffer + si + 1], al
    mov [buffer + si + 2], al
    mov [buffer + si + 3], dh
    
    add si, 4
    jmp Grey_Process_Loop
Grey_Write_Loop:
    mov ah, 40h
    mov bx, outHandle
    mov cx, si
    lea dx, buffer
    int 21h
    jmp Grey_Read_Loop
;------------------------------------------------------------------------------
; diff between th two codes is :-
; the first ignore the alpha byte 
; the second respect the structure of 32-bit image 
;------------------------------------------------------------------------------

; =============================================================================
; == FILTER 4: BINARY (Black & White for 32-bit BMP) [OPTIMIZED v2]          ==
; =============================================================================
Start_Binary_Filter:
Binary_Read_Loop:
    mov ah, 3Fh
    mov bx, inHandle
    mov cx, SIZE buffer
    lea dx, buffer
    int 21h
    jnc binary_read_ok
    jmp Exit_Failure
binary_read_ok:
    or ax, ax
    jnz binary_process_chunk
    jmp Exit_Success
binary_process_chunk:
    mov cx, ax
    mov si, 0
Binary_Process_Loop:
    cmp si, cx
    jae Binary_Write_Loop

    ; --- Use 16-bit sum (Your correct original logic) ---
    xor ax, ax                ; AX = 0
    mov al, [buffer + si]     ; AL = B
    xor bx, bx                ; BX = 0
    mov bl, [buffer + si + 1] ; BL = G
    add ax, bx                ; AX = B+G
    mov bl, [buffer + si + 2] ; BL = R
    add ax, bx                ; AX = B+G+R
    
    ; --- OPTIMIZATION v2: Replace slow DIV with fast MUL/SHR ---
    mov bx, 85
    mul bx                    ; DX:AX = AX * 85
    shr ax, 8                 ; AL = AH
    ; Result (average) is now in AL
    
    ; Binary threshold check
    cmp al, 90
    jae Set_White
Set_Black:
    mov byte ptr [buffer + si], 0
    mov byte ptr [buffer + si + 1], 0
    mov byte ptr [buffer + si + 2], 0
    jmp Store_Binary_Pixel
Set_White:
    mov byte ptr [buffer + si], 255
    mov byte ptr [buffer + si + 1], 255
    mov byte ptr [buffer + si + 2], 255
Store_Binary_Pixel:
    add si, 4
    jmp Binary_Process_Loop
Binary_Write_Loop:
    mov ah, 40h
    mov bx, outHandle
    mov cx, si
    lea dx, buffer
    int 21h
    jmp Binary_Read_Loop

; =============================================================================
; == PROGRAM EXIT POINTS                                                     ==
; =============================================================================
Invalid_Choice:
    mov ah, 00h        ; Set Video Mode , New Page
    mov al, 03h        ; Standard Text Mode 
    int 10h
    mov ah, 09h
    lea dx, invalidChoiceMsg
    int 21h
    jmp Exit_Failure_No_Close
    
;mov ah, 06h           ; Scroll Active Page Up
;mov al, 00h           ; Scroll to new page 
;mov bh, 07h           ; Background color
;mov cx, 0000h         ; CH, CL = 0, 0 (Top Left Angel)
;mov dx, 184Fh         ; DH=24 (row 25), DL=79 (col 80)
;int 10h
Exit_Success:
    mov ah, 3Eh        ;Close File Handeling
    mov bx, inHandle
    int 21h
    mov ah, 3Eh
    mov bx, outHandle
    int 21h
    mov ah, 00h
    mov al, 03h
    int 10h
    mov ah, 09h
    lea dx, successMsg
    int 21h
    mov ax, 4C00h       ;AH => Terminate Program & AL => Exit Code = 0 =Sucsseful
    int 21h
Exit_Failure:
    mov ah, 3Eh
    mov bx, inHandle
    int 21h
    mov ah, 3Eh
    mov bx, outHandle
    int 21h
    mov ah, 00h
    mov al, 03h
    int 10h
    mov ah, 09h
    lea dx, failureMsg
    int 21h
Exit_Failure_No_Close:
    mov ax, 4C01h           ;Al => Exit Code = 1 = Faild
    int 21h

MAIN ENDP
END MAIN
